# CRM web server

## Basic website setup
Install the apache2 package
```
apt install apache2
```

For the sake of the simplicity of this demonstration we'll ignore the actual underlying CRM website implementation details (i.e. database, scripts, static resources) and we'll focus solely on the authentication aspect.

After completing the installation process the new system user www-data will be automatically created. 

The next step is, if it doesn't exist yet, creating the directory `/var/www/` in which we will host the static website files.
The `var/www/` directory must be owned by www-data.
```
chown -R www-data:www-data /var/www/
```

## Integration of Kerberos authentication

The authentication-authorization will consist of three steps:
1) The main authentication will be handled by the mod_auth_gssapi Apache module. Its purpose is to expose a GSSAPI interface for the client to provide credentials, and to handle the Kerberos authentication process
2) Once authenticated, mod_auth_gssapi will feed to mod_authnz_ldap the now authenticated principal's name, which will be used to query the Kerberos-LDAP database to bind with the password the client provided

### Keytab and WebServer configuration

First we need to hop over to the kdc server and create a principal and its relative keytab for our webserver;
```
kadmin.local addprinc -pw secret HTTP/crm.mycompany.lan
kadmin.local ktadd -k crm.keytab HTTP/crm.mycompany.lan
```

The key will ultimately have to reside in our webserver, so it must be copied over in a secure way.
We'll store it as `/etc/apache2/http.keytab`


## LDAP-based authorization

To provide more advanced authorization mechanics we will rely on the same LDAP database which constitutes the backend for the Kerberos authentication system.

This authorization strategy relies on the Apache2 package **mod_authnz_ldap** in conjunction to **mod_ldap**.

In the LDAP database back over to the kdc server, we need to create an LDAP user for this website.

First, generate a hash for the password of your choice (I chose "secret" for simplicity)
```
root@kdc1:~# slappasswd -h {SHA}
New password: 
Re-enter new password: 
{SHA}{SHA}5en6G6MezRroT3XKqkdPOmY/BfQ=
```

Then create the LDAP user (remember to change the userPassword based on the result of the previous command)
```
ldapadd -x -D cn=admin,dc=mycompany,dc=lan -W << EOF
dn: uid=HTTP/crm.mycompany.lan@MYCOMPANY.LAN,cn=MYCOMPANY.LAN,cn=krbContainer,dc=mycompany,dc=lan
uid: HTTP/crm.mycompany.lan@MYCOMPANY.LAN
objectClass: account
objectClass: simpleSecurityObject
userPassword: {SHA}5en6G6MezRroT3XKqkdPOmY/BfQ=
description: Account used by crm.mycompany.lan for authorization purposes
EOF
```

Finally allow this user to read the realm subtree
```
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={1}mdb,cn=config
add: olcAccess
olcAccess: {2}to dn.subtree=cn=MYCOMPANY.LAN,cn=krbContainer,dc=mycompany,dc=lan
  by dn.exact="uid=HTTP/crm.mycompany.lan@MYCOMPANY.LAN,cn=MYCOMPANY.LAN,cn=krbContainer,dc=mycompany,dc=lan" read
  by * read
EOF
```
