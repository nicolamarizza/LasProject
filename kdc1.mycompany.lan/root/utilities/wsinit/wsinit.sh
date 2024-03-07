#!/bin/bash

cd /root/utilities/wsinit

read -p "department: " DEP
read -p "workstation number: " WS_NO

WS_IP=ws$WS_NO.$DEP.mycompany.lan

DEP=$(echo $WS_IP | cut -d. -f2)

echo "apt update && apt install -y nfs-common autofs krb5-user libpam-krb5 chrony" | ssh root@$WS_IP "bash -s"  

TEMP_DIR=$(mktemp -d)
cp -r ./etc $TEMP_DIR/

find $TEMP_DIR -type f -exec sed -i "s/WS_DEP/$DEP/g" {} \;

scp -r $TEMP_DIR/etc root@$WS_IP:/

ssh root@$WS_IP systemctl restart autofs chrony

rm -r $TEMP_DIR
