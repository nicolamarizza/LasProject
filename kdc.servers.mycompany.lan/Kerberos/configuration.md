## Kerberos configuration

Install the following package
```
apt install krb5-admin-server
```

Create the realm
```
kdb5_ldap_util -D cn=admin,dc=mycompany,dc=lan create -r MYCOMPANY.LAN -s -H ldapi:///
```

Add the `/etc/krb5kdc/kadm5.acl` file which defines the access permissions to the administration server and give full permissions to any principal with the admin instance inside the MYCOMPANY.LAN realm.
```
*/admin@MYCOMPANY.LAN *
```
