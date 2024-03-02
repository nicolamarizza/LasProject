# Setup LDAP backend for Kerberos


## LDAP database configuration

Install the following packages
```
apt install slapd krb5-kdc-ldap
```

Configure slapd (see screenshots)
```
dpkg-reconfigure slapd
```

With krb5-kdc-ldap comes a default LDAP database schema that Kerberos uses to interact with the database.
```
cp /usr/share/doc/krb5-kdc-ldap/kerberos.schema.gz /etc/ldap/schema/
gunzip /etc/ldap/schema/kerberos.schema.gz
```

The schema can now be imported as LDIF and added to the `cn=config` tree
```
ldap-schema-manager -i kerberos.schema
```

Kerberos needs administrative entities with specific permissions to update and search the DIT structure, these entities are `kdc-service` and `kadmin-service`.
Create both entities by logging into the default slapd admin account

```
ldapadd -x -D cn=admin,dc=mycompany,dc=lan -W << EOF
dn: uid=kdc-service,dc=mycompany,dc=lan
uid: kdc-service
objectClass: account
objectClass: simpleSecurityObject
userPassword: {CRYPT}x
description: Account used for the Kerberos KDC

dn: uid=kadmin-service,dc=mycompany,dc=lan
uid: kadmin-service
objectClass: account
objectClass: simpleSecurityObject
userPassword: {CRYPT}x
description: Account used for the Kerberos Admin server
EOF
```

The directive `userPassword: {CRYPT}x` only tells slapd to encrypt stored passwords by using `x` as a placeholder.
Now define a password for both entities:
```
ldappasswd -x -D cn=admin,dc=mycompany,dc=lan -W -S uid=kdc-service,dc=mycompany,dc=lan
ldappasswd -x -D cn=admin,dc=mycompany,dc=lan -W -S uid=kadmin-service,dc=mycompany,dc=lan
```

Finally set the appropriate permissions for these entities in the ACL
Note the double spaces for indentation!
```
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={1}mdb,cn=config
add: olcAccess
olcAccess: {2}to attrs=krbPrincipalKey
  by anonymous auth
  by dn.exact="uid=kdc-service,dc=mycompany,dc=lan" read
  by dn.exact="uid=kadmin-service,dc=mycompany,dc=lan" write
  by self write
  by * none
-
add: olcAccess
olcAccess: {3}to dn.subtree="cn=krbContainer,dc=mycompany,dc=lan"
  by dn.exact="uid=kdc-service,dc=mycompany,dc=lan" read
  by dn.exact="uid=kadmin-service,dc=mycompany,dc=lan" write
  by * none
EOF
```

`cn=krbContainer,dc=mycompany,dc=lan` is location under which Kerberos principals will be stored.


## Kerberos configuration

Now that the LDAP server is ready all we need to do is load the appropriate modules and configure them to tell the KDC to actually use it.

Install the following package
```
apt install krb5-admin-server
```

copy /etc/krb5.conf and /etc/krb5kdc/kdc.conf

Notable directives:
- **ldap_kerberos_container_dn** as we just saw is location under which Kerberos principals will be stored.
- **ldap_kdc_dn** is the DN of the kdc-service entity we created in the previous section
- **ldap_kadmind_dn** is the DN of the kadmind-service entity we created in the previous section
- **ldap_service_password_file** is the file that contains the previous entities' hashed passwords
- **ldap_servers** where the LDAP server is hosted (in this case it's the same host as the KDC)


Create a stash of the password used to bind to the LDAP server.
```
kdb5_ldap_util -D cn=admin,dc=mycompany,dc=lan stashsrvpw -f /etc/krb5kdc/service.keyfile uid=kdc-service,dc=mycompany,dc=lan
kdb5_ldap_util -D cn=admin,dc=mycompany,dc=lan stashsrvpw -f /etc/krb5kdc/service.keyfile uid=kadmin-service,dc=mycompany,dc=lan
```

Create the realm
```
kdb5_ldap_util -D cn=admin,dc=mycompany,dc=lan create -r MYCOMPANY.LAN -s -H ldapi:///
```

Now create two organizational units each for a subnet in our network, namely **sales** and **customercare**
```
ldapadd -x -H ldapi:/// -D "cn=admin,dc=mycompany,dc=lan" -W <<EOF
dn: ou=sales,cn=MYCOMPANY.LAN,cn=krbContainer,dc=mycompany,dc=lan
objectClass: organizationalUnit
ou: sales

dn: ou=customercare,cn=MYCOMPANY.LAN,cn=krbContainer,dc=mycompany,dc=lan
objectClass: organizationalUnit
ou: customercare
EOF
```

Add the `/etc/krb5kdc/kadm5.acl` file which defines the access permissions to the administration server and give full permissions to any principal with the admin instance inside the MYCOMPANY.LAN realm.
```
*/admin@MYCOMPANY.LAN *
```

Finally, start the KDC and admin servers
```
systemctl start krb5-kdc.service krb5-admin-server.service
```

Now, to add a principal see `addprinc.sh`
