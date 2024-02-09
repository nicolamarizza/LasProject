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

Then we'll need to create a configuration file for the CRM website, which will be located under `/etc/apache2/conf-available/crm.conf`

```
<VirtualHost *:80>
    ServerAdmin         webmaster@localhost
    ServerName          crm.mycompany.lan
    DocumentRoot        /var/www/crm/
    ErrorLog            /var/log/apache2/crm.error.log
    CustomLog           /var/log/apache2/crm.access.log combined
</VirtualHost>
```

We'll see what the LoadModule directive refers to in the next section.

## Integration of Kerberos authentication

The authentication-authorization will consist of three steps:
1) The main authentication will be handled by the mod_auth_gssapi Apache module. Its purpose is to expose a GSSAPI interface for the client to provide credentials, and to handle the Kerberos authentication process
2) Once authenticated, mod_auth_gssapi will feed to mod_authnz_ldap the now authenticated principal's name, which will be used to query the Kerberos-LDAP database to bind with the password the client provided

### mod_auth_gssapi

The authentication process will be c

Support for Kerberos will be carried out by the SPNEGO authentication system.
Since Apache does not natively support SPNEGO we will have to install an additional module:
```
apt install libapache2-mod-auth-kerb
```
This module has to be enabled with a **LoadModule** directive in the `/etc/apache2/conf-available/crm.conf` configuration file in the previous section.
Simply insert inside the **\<VirtualHost\>** context the following directive:
```
LoadModule  auth_kerb_module /usr/lib/apache2/modules/mod_auth_kerb.so
```

After that we need to create a server principal, which will be used by SPNEGO to authenticate the webserver towards the KDC server.
Creating a new principal can be done by the KDC server like so:
```
kadmin -p admin/admin -q "addprinc -randkey HTTP/crm.mycompany.lan"
```

Of course the principal that carries out this operation doesn't have to necessarily be admin/admin, it can be any principal who has addprinc permissions.

### Keytab and WebServer configuration

A keytab must created for this principal, this can be achieved KDC server side like so:
```
kadmin -p admin/admin -q "ktadd -k /your/path/of/choice/http.keytab HTTP/www.example.com"
```

The key will ultimately need to reside in the CRM server, so it must be copied over (preferrably via SCP).
We'll store it as `/etc/apache2/http.keytab`


The `/etc/apache2/conf-available/crm.conf` needs to be configured accordingly by inserting inside the **\<VirtualHost\>** context the following block.
```
<Location />
    AuthType Kerberos
    AuthName "MyCompany CRM"
    KrbMethodNegotiate on
    KrbMethodK5Passwd off
    Krb5Keytab /etc/apache2/http.keytab
</Location>
```

**Location /** means that the wole website is behind Kerberos authentication, **AuthName** is a mnemonic name that gives clients connecting to the website an indication of what password is needed. Although the authentication process should require no password this directive is required. **KrbMethodNegotiate** enables the use of the Negotiate method.


### LDAP database configuration

The default Apache behavior in regard to website access is to allow anonymous users. This behavior needs to be overridden in favor of the Kerberos authentication system.
Apache configuration files natively support the **Requre** directive, which is to be placed in a **\<VirtualHost\>** context, and any principal that follows will be allowed to access.
Since this solution is poorly scalable, we will resort to a more flexible method, which stores known principals in a locally hosted LDAP database.

We will use the OpenLDAP implementation, available from the distribution repository:
```
apt install slapd
```
You will be prompted to choose an administrator password for the LDAP database and to confirm it.

This authorization strategy relies on two native Apache2 packages, namely **mod_ldap** and **mod_authnz_ldap**.
The former provides a series of optimizations on LDAP accesses, while the latter allows authentication front-ends to authenticate users through an LDAP database.
Enable both modules by inserting the following directive in the  **\<VirtualHost\>** context:

```
LoadModule  ldap_module /usr/lib/apache2/modules/mod_ldap.so
LoadModule  authnz_ldap_module /usr/lib/apache2/modules/mod_authnz_ldap.so
```

## GSSAPI installation
Required packages to copile the module
```
apt install flex bison pkg-config libtool autoconf apache2_dev libssl-dev libkrb5-dev
```
Download the latest GSSAPI release (at the time of this walkthrough it's [Release 1.6.5](https://github.com/gssapi/mod_auth_gssapi/releases/tag/v1.6.5))

After extracting it, cd into **mod_auth_gssapi-1.6.5** and execute
```
autoreconf -fi
./configure
make
make install
```



Add read privileges to HTTP principals

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