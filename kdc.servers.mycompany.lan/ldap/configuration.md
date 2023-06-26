# LDAP database configuration

Install slapd
```
apt install slapd ldap-utils
```

Append the following lines to `/etc/ldap/ldap.conf`
```
BASE dc=mycompany,dc=lan
URI ldapi:///
```

Apply configuration changes
```
systemctl restart slapd
```

Set the base domain name to **mycompany.lan** and the organization name to **mycompany**
```
dpkg-reconfigure slapd
```

Install the following packages.
You will be asked to input the default kdc and admin servers DNSs as well as the realm name.
Set the default kdc and admin server DNSs to **kdc1.mycompany.lan** and the realm name to **MYCOMPANY.LAN**
```
apt install krb5-kdc-ldap krb5-admin-server
```

With these packages comes a default LDAP database schema that Kerberos uses to interact with the database.
```
cp /usr/share/doc/krb5-kdc-ldap/kerberos.schema.gz /etc/ldap/schema/
gunzip /etc/ldap/schema/kerberos.schema.gz
```


Append the **employee** attribute to the `/etc/ldap/schema/kerberos.schema`. The necessity of this attribute will be further explained in the Apache CRM server authentication section.
```
attributeType  ( 2.16.840.1.113700.1.301.4.46.1
                NAME 'employee'
                DESC 'Employee DN Array'
                EQUALITY distinguishedNameMatch
                SYNTAX 1.3.6.1.4.1.1466.115.121.1.12{32768}
                X-ORIGIN 'Custom' )

objectclass ( 2.16.840.1.113700.1.301.4.46.2
                NAME 'department'
                SUP organizationalUnit
                MAY ( employee ) )

```
Note that you might need to customize the OIDs.

To be imported, the new schema needs to be converted to LDIF format, which can be achieved by the following tool
```
apt install schema2ldif
```

The schema can now be imported as LDIF and added to the `cn=config` tree
```
ldap-schema-manager -i kerberos.schema
```

Add an index that will speed up searches done by the KDC. This step is optional
```
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={1}mdb,cn=config
add: olcDbIndex
olcDbIndex: krbPrincipalName eq,pres,sub
EOF
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


Now define a password for both entities:
```
ldappasswd -x -D cn=admin,dc=mycompany,dc=lan -W -S uid=kdc-service,dc=mycompany,dc=lan
ldappasswd -x -D cn=admin,dc=mycompany,dc=lan -W -S uid=kadmin-service,dc=mycompany,dc=lan
```

Finally set the appropriate permissions for these entities in the ACL
`cn=krbContainer,dc=mycompany,dc=lan` is location under which Kerberos principals will be stored.
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

You can now go over to the Kerberos configuration section