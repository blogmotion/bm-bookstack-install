#!/bin/bash
# bm-bookstack-install : Installation de BookStack pour Alma Linux 8.x et Oracle Linux 8.x
# License : Creative Commons http://creativecommons.org/licenses/by-nd/4.0/deed.fr
# Website : https://blogmotion.fr/internet/bookstack-script-installation-centos-8-18255
#
# BookStack : https://www.bookstackapp.com/
# Adapted from : https://deviant.engineer/2017/02/bookstack-centos7/
#
#set -xe
VERSION="2024.02.28"

### VARIABLES #######################################################################################################################
VARWWW="/var/www"
BOOKSTACK_DIR="${VARWWW}/BookStack"
TMPROOTPWD="/tmp/DB_ROOT.delete"
REMIRPM="https://rpms.remirepo.net/enterprise/remi-release-8.rpm"
CURRENT_IP=$(hostname -i)
EMAIL_SENDER="$(whoami)@$(hostname -f)"

blanc="\033[1;37m"; gris="\033[0;37m"; magenta="\033[0;35m"; rouge="\033[1;31m"; vert="\033[1;32m"; jaune="\033[1;33m"; bleu="\033[1;34m"; rescolor="\033[0m"


### START SCRIPT #################################################################################################################### 
echo -e "${vert}"
echo -e "#########################################################"
echo -e "#                                                       #"
echo -e "#                BookStack Installation                 #"
echo -e "#                                                       #"
echo -e "#         Tested on Alma, Oracle Linux 8.9 (x64)        #"
echo -e "#                      by @xhark                        #"
echo -e "#                                                       #"
echo -e "###################### ${VERSION} #######################"
echo -e "${rescolor}\n\n"
sleep 3

echo -e "\n${jaune}SELinux disable and firewall settings ...${rescolor}" && sleep 1
sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config && setenforce 0
firewall-cmd --add-service=http --permanent && firewall-cmd --add-service=https --permanent && firewall-cmd --reload


### PACKAGES INSTALLATION ##########################################################################################################
echo -e "\n${jaune}Packages installation ...${rescolor}" && sleep 1

dnf -y update
dnf -y install epel-release # (Extra Packages for Enterprise Linux)
yum -y install git unzip mariadb-server nginx php php-cli php-fpm php-json php-gd php-mysqlnd php-xml php-openssl php-tokenizer php-mbstring php-mysqlnd																																						

# Add REMI repo
dnf -y install $REMIRPM

if [[ $? -ne 0 ]]; then
        echo -e "\t ${rouge} ERROR on Remi RPM, please check RPM URL : $REMIRPM ${rescolor}"
        echo -e "\t ${gris} script aborted, please restart after fix it ${rescolor}"
		exit 1
fi

dnf config-manager --set-enabled powertools
dnf -y module reset php
dnf -y module install php:remi-8.1
dnf --enablerepo=remi install -y php81-php-tidy php81-php-json php81-php-pecl-zip


# create symlink tidy.so and enable extension in php.ini
ln -s /opt/remi/php81/root/usr/lib64/php/modules/tidy.so /usr/lib64/php/modules/tidy.so
echo "extension=tidy" >> /etc/php.ini


### Database setup ###############################################################################################################
echo -e "\n${jaune}Database installation ...${rescolor}" && sleep 1
systemctl enable --now mariadb.service
printf "\n n\n n\n n\n y\n y\n y\n" | mysql_secure_installation

mysql --execute="
CREATE DATABASE IF NOT EXISTS bookstackdb DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT ALL PRIVILEGES ON bookstackdb.* TO 'bookstackuser'@'localhost' IDENTIFIED BY 'bookstackpass' WITH GRANT OPTION;
FLUSH PRIVILEGES;
quit"

# Set root password
DB_ROOT=$(cat /dev/urandom | tr -cd 'A-Za-z0-9' | head -c 14)
echo "MariaDB root:${DB_ROOT}" >> $TMPROOTPWD && cat $TMPROOTPWD
mysql -e "SET PASSWORD FOR root@localhost = PASSWORD('${DB_ROOT}');FLUSH PRIVILEGES;"


### PHP-FPM setup ###############################################################################################################
echo -e "\n${jaune}PHP-FPM configuration ...${rescolor}" && sleep 1
fpmconf=/etc/php-fpm.d/www.conf
sed -i "s|^listen =.*$|listen = /run/php-fpm.sock|" $fpmconf
sed -i "s|^;listen.owner =.*$|listen.owner = nginx|" $fpmconf
sed -i "s|^;listen.group =.*$|listen.group = nginx|" $fpmconf
sed -i "s|^user = apache.*$|user = nginx ; PHP-FPM running user|" $fpmconf
sed -i "s|^group = apache.*$|group = nginx ; PHP-FPM running group|" $fpmconf
sed -i "s|^php_value\[session.save_path\].*$|php_value[session.save_path] = ${VARWWW}/sessions|" $fpmconf


### NGINX SETUP #################################################################################################################
echo -e "\n${jaune}nginx configuration ...${rescolor}" && sleep 1
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.BAK

cat << '_EOF_' > /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;
}
_EOF_

cat << '_EOF_' > /etc/nginx/conf.d/bookstack.conf
server {
  listen 80;
  
  #HTTP conf:
  #listen 443 ssl;
  #ssl_certificate /etc/pki/tls/blogmotion/monserveur.crt;
  #ssl_certificate_key /etc/pki/tls/blogmotion/monserveur.key;
  #ssl_protocols TLSv1.2;
  #ssl_prefer_server_ciphers on;

  server_name _;

  root /var/www/BookStack/public;

  access_log  /var/log/nginx/bookstack_access.log;
  error_log  /var/log/nginx/bookstack_error.log;

  client_max_body_size 1G;
  fastcgi_buffers 64 4K;

  index  index.php;

  location / {
    try_files $uri $uri/ /index.php?$query_string;
  }

  location ~ ^/(?:\.htaccess|data|config|db_structure\.xml|README) {
    deny all;
  }

  location ~ \.php(?:$|/) {
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param PATH_INFO $fastcgi_path_info;
    fastcgi_pass unix:/var/run/php-fpm.sock;
  }

  location ~* \.(?:jpg|jpeg|gif|bmp|ico|png|css|js|swf)$ {
    expires 30d;
    access_log off;
  }
}
_EOF_

# Enable and start services
systemctl enable --now nginx.service
systemctl enable --now php-fpm.service


### BOOKSTACK INSTALLATION ################################################################################################################
echo -e "\n${jaune}BookStack installation ...${rescolor}" && sleep 1
mkdir -p ${VARWWW}/sessions # php sessions

# Clone the latest from the release branch
git clone https://github.com/BookStackApp/BookStack.git --branch release --single-branch ${BOOKSTACK_DIR}

# let composer do it's things
cd /usr/local/bin
curl -sS https://getcomposer.org/installer | php
mv composer.phar composer
cd ${BOOKSTACK_DIR}
composer install

# Config file injection
cp .env.example .env
sed -i "s|APP_URL=.*$|APP_URL=http://${CURRENT_IP}|" .env
sed -i "s|^DB_DATABASE=.*$|DB_DATABASE=bookstackdb|" .env
sed -i "s|^DB_USERNAME=.*$|DB_USERNAME=bookstackuser|" .env
sed -i "s|^DB_PASSWORD=.*$|DB_PASSWORD=bookstackpass|" .env
sed -i "s|^MAIL_PORT=.*$|MAIL_PORT=25|" .env
sed -i "s|^MAIL_FROM=.*$|MAIL_FROM=${EMAIL_SENDER}|" .env

# Set in French if locale is FR
lang=$(locale | grep LANG | cut -d= -f2 | cut -d_ -f1)
if [[ $lang -eq "fr" ]]; then
	sed -i "s|^# Application URL.*$|APP_LANG=fr\n# Application URL|" .env
fi

# Generate and update APP_KEY in .env
php artisan key:generate --no-interaction --force

# Generate database tables and other settings
php artisan migrate --force

# Fix rights
chown -R nginx:nginx /var/www/{BookStack,sessions}
chmod -R 755 bootstrap/cache public/uploads storage

echo -e "\n\n"
echo -e "\t       ${vert}SUCCESS ! ${rescolor}"
echo -e "\t * 1 * ${vert}PLEASE NOTE the MariaDB password root:${DB_ROOT} ${rescolor}"
echo -e "\t * 2 * ${rouge}AND DELETE the file (or reboot) ${TMPROOTPWD} ${rescolor}"
echo -e "\t * 3 * ${bleu}Logon URL http://${CURRENT_IP} \n\t\t -> with admin@admin.com and 'password' ${rescolor}"
echo -e "\n\t${magenta} --- END OF SCRIPT (v${VERSION}) ---  \n\n\n ${rescolor}"

exit 0