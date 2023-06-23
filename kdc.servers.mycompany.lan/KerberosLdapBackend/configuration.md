# Setup LDAP backend for Kerberos


## LDAP database configuration

Install the following packages
```
apt install krb5-kdc-ldap krb5-admin-server
```

With these packages comes a default LDAP database schema that Kerberos uses to interact with the database.
```
cp /usr/share/doc/krb5-kdc-ldap/kerberos.schema.gz /etc/ldap/schema/
gunzip /etc/ldap/schema/kerberos.schema.gz
```

To be able to add the schema it needs to be converted to LDIF format, which can be achieved by installing an additional repository package
```
apt install schema2ldif
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

Append the following directives inside `/etc/krb5kdc/kdc.conf`
```
[dbdefaults]
        ldap_kerberos_container_dn = cn=krbContainer,dc=mycompany,dc=lan

[dbmodules]
        openldap_ldapconf = {
                db_library = kldap

                # if either of these is false, then the ldap_kdc_dn needs to
                # have write access
                disable_last_success = true
                disable_lockout  = true

                # this object needs to have read rights on
                # the realm container, principal container and realm sub-trees
                ldap_kdc_dn = "uid=kdc-service,dc=mycompany,dc=lan"

                # this object needs to have read and write rights on
                # the realm container, principal container and realm sub-trees
                ldap_kadmind_dn = "uid=kadmin-service,dc=mycompany,dc=lan"

                ldap_service_password_file = /etc/krb5kdc/service.keyfile
                ldap_servers = ldapi:///
                ldap_conns_per_server = 5
        }
```

Notable directives:
- **ldap_kerberos_container_dn** as we just saw is location under which Kerberos principals will be stored.
- **ldap_kdc_dn** is the DN of the kdc-service entity we created in the previous section
- **ldap_kadmind_dn** is the DN of the kadmind-service entity we created in the previous section
- **ldap_service_password_file** is the file that contains the previous entities' hashed passwords
- **ldap_servers** where the LDAP server is hosted (in this case it's the same host as the KDC)


Create the realm
```
LDAP_BASE_DN="dc=mycompany,dc=lan"
        
kdb5_ldap_util -D cn=admin,dc=mycompany,dc=lan create -subtrees ou=sales,${LDAP_BASE_DN}:ou=customercare,${LDAP_BASE_DN}:${LDAP_BASE_DN} -r MYCOMPANY.LAN -s -H ldapi:///
```

Notable parameters
- **subtrees** defines the subtrees under which kerberos principals will be placed, in our example we have two departments plus the common resources (kdc, crm, homes)
- **sscope** scope under which Kerberos will search for principals, we set it to SUB so that all subtrees (above defined) will be searched


Now create two organizational units each for a subnet in our network, namely **sales** and **customercare**
```
ldapadd -x -H ldapi:/// -D "cn=admin,dc=mycompany,dc=lan" -W <<EOF
dn: ou=sales,cn=MYCOMPANY.LAN,cn=krbContainer,dc=mycompany,dc=lan
objectClass: top
objectClass: organizationalUnit
ou: sales

dn: ou=customercare,cn=MYCOMPANY.LAN,cn=krbContainer,dc=mycompany,dc=lan
objectClass: top
objectClass: organizationalUnit
ou: customercare
EOF
```

Now, to add a principal, first add an entry in the DIT:
```
ldapadd -x -H ldapi:/// -D "cn=admin,dc=mycompany,dc=lan" -w $LDAP_MASTER_PWD <<EOF
dn: cn=$PRINC_NAME,ou=$PRINC_DEP,$BASE_DN
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
cn: $PRINC_NAME
sn: $PRINC_DEP
EOF
```

Then, bind a new principal to it:
```
kadmin.local -q "addprinc -pw \"$PRINC_PWD\" -x dn=cn=$PRINC_NAME,ou=$PRINC_DEP,$BASE_DN $PRINC_NAME/$PRINC_DEP@MYCOMPANY.LAN"
```
