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
kadmin.local addprinc -randkey HTTP/crm.mycompany.lan
kadmin.local ktadd -k crm.keytab HTTP/crm.mycompany.lan
```

The key will ultimately have to reside in our webserver, so it must be copied over in a secure way.
We'll store it as `/etc/apache2/http.keytab`


## LDAP-based authorization

To provide more advanced authorization mechanics we will rely on the same LDAP database which constitutes the backend for the Kerberos authentication system.

This authorization strategy relies on the Apache2 package **mod_authnz_ldap** which caches authentication and authorization results based on the configuration of **mod_ldap**.

In the LDAP database back over to the kdc server, we need to add read permissions to the webserver pricipal

```
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={1}mdb,cn=config
add: olcAccess
olcAccess: {2}to attrs=krbPrincipalName
  by anonymous auth
  by dn.exact="cn=HTTP,cn=MYCOMPANY.LAN,cn=krbContainer,dc=mycompany,dc=lan" read
  by self write
  by * none
-
add: olcAccess
olcAccess: {3}to dn.subtree="cn=krbContainer,dc=mycompany,dc=lan"
  by dn.exact="cn=HTTP,cn=MYCOMPANY.LAN,cn=krbContainer,dc=mycompany,dc=lan" read
  by * none
EOF
```
