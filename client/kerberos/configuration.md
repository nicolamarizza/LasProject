Install the Kerberos client package
```
apt install krb5-user
```

Copy the configuration file from `vmroot/etc/krb5.conf`

To automatically obtain a ticket-granting-ticket on login, install `libpam-krb5`
```
apt install libpam-krb5
```

Copy the configuration files from `vmroot/etc/pam.d`.
Remember to change the directive `alt_auth_map=%s/sales` according to which department the client is located at
