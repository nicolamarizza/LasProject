# NTP

To serve DNS to our company LAN we will use chrony

## Installation

chrony can be installed from the distibution repository:

```
apt install chrony
```

## Configuration

A few lines have to be added to the /etc/chrony/chrony.conf configuration file.

```
server 127.0.0.1
allow 192.168.3.0/24
allow 192.168.4.0/24
allow 192.168.5.0/24
```

The first line tells the NTP server to synchronize with itself.
The second to fourth lines allow the NTP server to serve to all the LAN subnets.

Finally restart chrony for the changes to take effect.
```
systemctl restart chrony
```