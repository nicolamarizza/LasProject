# Kerberos configuration

Also insert in the `/etc/krb5.conf` file the following line, inside the MYCOMPANY.REALM scope
```
[libdefaults]
        default_realm = MYCOMPANY.LAN

[realms]
        MYCOMPANY.LAN = {
                kdc = kdc1.mycompany.lan
                admin_server = kdc1.mycompany.lan
                default_domain = mycompany.lan
                database_module = openldap_ldapconf
        }
```

And append these lines to that same file
```
[dbdefaults]
        ldap_kerberos_container_dn = cn=krbContainer,dc=mycompany,dc=lan

[dbmodules]
        MYCOMPANY.LAN = {
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
kdb5_ldap_util -D cn=admin,dc=mycompany,dc=lan create -subtrees dc=mycompany,dc=lan -r MYCOMPANY.LAN -s -H ldapi:///
```

Create a stash of the password used to bind to the LDAP server.
```
kdb5_ldap_util -D cn=admin,dc=mycompany,dc=lan stashsrvpw -f /etc/krb5kdc/service.keyfile uid=kdc-service,dc=mycompany,dc=lan
kdb5_ldap_util -D cn=admin,dc=mycompany,dc=lan stashsrvpw -f /etc/krb5kdc/service.keyfile uid=kadmin-service,dc=mycompany,dc=lan
```

Add the `/etc/krb5kdc/kadm5.acl` file which defines the access permissions to the administration server and give full permissions to any principal with the admin instance inside the MYCOMPANY.LAN realm.
```
*/admin@MYCOMPANY.LAN *
```

Now create two organizational units each for a subnet in our network, namely **sales** and **customercare**
```
ldapadd -x -H ldapi:/// -D "cn=admin,dc=mycompany,dc=lan" -W <<EOF
dn: ou=sales,cn=MYCOMPANY.LAN,cn=krbContainer,dc=mycompany,dc=lan
objectClass: top
objectClass: department
ou: sales

dn: ou=customercare,cn=MYCOMPANY.LAN,cn=krbContainer,dc=mycompany,dc=lan
objectClass: top
objectClass: department
ou: customercare
EOF
```

Finally, start the KDC and admin servers
```
systemctl start krb5-kdc.service krb5-admin-server.service
```

TODO: find a way to add long files to documentation in an elegant way
To add a principal check [addprinc.sh](kdc.servers.mycompany.lan/KerberosLdapBackend/addprinc.sh)
