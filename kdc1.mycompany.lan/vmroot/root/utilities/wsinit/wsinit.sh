#!/bin/bash

cd /root/utilities/wsinit

read -p "department: " DEP
read -p "workstation number: " WS_NO

WS_IP=ws$WS_NO.$DEP.mycompany.lan

DEP=$(echo $WS_IP | cut -d. -f2)

ssh root@$WS_IP "bash -s" -- $DEP < ./init_remote.sh

TEMP_DIR=$(mktemp -d)
cp -r ./etc $TEMP_DIR/

sed -i "s/WS_DEP/$DEP/g" $TEMP_DIR/etc/pam.d/*

scp -r $TEMP_DIR/etc root@$WS_IP:/

rm -r $TEMP_DIR
