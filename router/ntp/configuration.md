# NTP

By default ubuntu machines run timedatectl and timesyncd.

While for the clients these packages would be enough, we will install chrony, which is a more
advanced equivalent of timesyncd.

We will also use chrony server-side to serve NTP.


## Server configuration

Install the chrony package:

```
apt install chrony
```

In the `/etc/chront/chrony.conf` allow the LAN subnets
```
allow 192.168.1.0/24
allow 192.168.2.0/24
allow 192.168.3.0/24
```

Then choose the closest NTP server pools to your location, you can consult [this website](https://support.ntp.org/bin/view/Servers/NTPPoolServers)

In my case they are
```
pool 0.it.pool.ntp.org
pool 1.it.pool.ntp.org
pool 2.it.pool.ntp.org
pool 3.it.pool.ntp.org
```

Finally restart chrony
```
systemctl restart chrony
```


## Client configuration

The following steps are to be executed for each NTP client in the company lan


Install the chrony package:

```
apt install chrony
```

In the `/etc/chront/chrony.conf` we need to tell the client to use ntp.mycompany.lan
as their only server reference. This can be done by swapping the default `pool` directives
with 
```
server ntp.mycompany.lan
```

Finally restart chrony
```
systemctl restart chrony
```

Optionally we can check the status of our sync by running `chronyc sources`.
The output should look like this:
```
$ chronyc sources

MS Name/IP address         Stratum Poll Reach LastRx Last sample               
===============================================================================
^* _gateway                      3   9   377   227    -71us[  -95us] +/-   13ms
```

