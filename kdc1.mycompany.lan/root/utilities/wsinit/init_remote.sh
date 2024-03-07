#!/bin/bash

DEP=$1

apt update
apt install nfs-common autofs krb5-user libpam-krb5 chrony

echo -e "/home\t/etc/auto.home" >> /etc/auto.master
echo -e "*\t-fstype=nfs4,rw\thomes.mycompany.lan:/homes/$DEP/&" > /etc/auto.home

systemctl restart autofs

sed -i /^pool/d /etc/chrony/chrony.conf
echo "server ntp.mycompany.lan iburst" >> /etc/chrony/chrony.conf

systemctl restart chrony
