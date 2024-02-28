bm-bookstack-install (installation auto. de BookStack)
===

> english version below

### Description
Ce script automatise l'installation de [BookStack](https://www.bookstackapp.com) sur les distributions basées sur RHEL (à vos risques et périls).

Présentation : https://blogmotion.fr/internet/bookstack-script-installation-centos-8-18255

Validé sur :

- Alma Linux 8.9 (x64)


### 🚀 Utilisation
En tant que root (ou via sudo) :
```chmod +x bookstack-install-centos8.sh && ./bookstack-install-centos8.sh```

### LDAP avec Active Directory
Extrait de fichier `.env`

Connexion à un serveur LDAP **Active Directory** **_non sécurisé_** (port 389):
```
# LDAP authentication configuration - Refer to https://www.bookstackapp.com/docs/admin/ldap-auth/
# AUTH_METHOD=standard => pour repasser en connexion locale avec admin@admin.com
AUTH_METHOD=ldap
LDAP_SERVER=ldap://bm.loc:389
LDAP_VERSION=3
LDAP_ID_ATTRIBUTE=objectGUID
LDAP_BASE_DN="OU=Mes Utilisateurs,DC=bm,DC=loc"

# Identifiant de connexion au format LDAP 
#LDAP_DN="CN=ldap-bookstack,CN=Users,DC=bm,DC=loc"
# Identifiant de connexion au format court - attention: pas de guillemet)
LDAP_DN=ldap-bookstack@bm.loc
LDAP_PASS="**********"

# filtre de connexion, membre du groupe AD GRP_BookStack - login OU email OU SamAccountName ou UPN
LDAP_USER_FILTER="(&(|(sAMAccountName=${user})(userPrincipalName=${user})(mail=${user}))(memberOf=CN=GRP_BookStack,OU=Mes groupes,DC=bm,DC=loc))"

# commenter pour se co avec un compte sans email:
#LDAP_EMAIL_ATTRIBUTE=mail

LDAP_DISPLAY_NAME_ATTRIBUTE=cn
LDAP_FOLLOW_REFERRALS=true

LDAP_USER_TO_GROUPS=true
LDAP_GROUP_ATTRIBUTE="memberOf"
LDAP_REMOVE_FROM_GROUPS=false

```

Connexion à un serveur LDAP **Active Directory** TLS **_sécurisé_** (port 636):
```
# LDAP authentication configuration - Refer to https://www.bookstackapp.com/docs/admin/ldap-auth/
# AUTH_METHOD=standard => pour repasser en connexion locale avec admin@admin.com
AUTH_METHOD=ldap
LDAP_SERVER=ldaps://bm.loc:636
LDAP_VERSION=3
LDAP_ID_ATTRIBUTE=objectGUID
LDAP_BASE_DN="OU=Mes Utilisateurs,DC=bm,DC=loc"

# If you need to allow untrusted LDAPS certificates, add the below and uncomment (remove the #)
# Only set this option if debugging or you're absolutely sure it's required for your setup.
#LDAP_TLS_INSECURE=true

# Identifiant de connexion au format LDAP 
#LDAP_DN="CN=ldap-bookstack,CN=Users,DC=bm,DC=loc"
# Identifiant de connexion au format court - attention: pas de guillemet)
LDAP_DN=ldap-bookstack@bm.loc
LDAP_PASS="**********"

# filtre de connexion, membre du groupe AD GRP_BookStack - login OU email OU SamAccountName ou UPN
LDAP_USER_FILTER="(&(|(sAMAccountName=${user})(userPrincipalName=${user})(mail=${user}))(memberOf=CN=GRP_BookStack,OU=Mes groupes,DC=bm,DC=loc))"

# commenter pour se co avec un compte sans email:
#LDAP_EMAIL_ATTRIBUTE=mail

LDAP_DISPLAY_NAME_ATTRIBUTE=cn
LDAP_FOLLOW_REFERRALS=true

LDAP_USER_TO_GROUPS=true
LDAP_GROUP_ATTRIBUTE="memberOf"
LDAP_REMOVE_FROM_GROUPS=false

```



### English version

### [EN] Description
This script automates the installation of [BookStack](https://www.bookstackapp.com), only for RedHat based distributions (at your own risk).

How to (french): https://blogmotion.fr/internet/bookstack-script-installation-centos-8-18255)

Tested on :

- Alma Linux 8.9 (x64)

### [EN] 🚀 Usage
Run as root (or prefix with sudo) :
```chmod +x bookstack-install-centos8.sh && ./bookstack-install-centos8.sh```
