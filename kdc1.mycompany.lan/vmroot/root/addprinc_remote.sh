#!/bin/bash

PRINC_NAME=$1
PRINC_DEP=$2
USER_UID=$3
USER_GID=$4
PRINC_PWD=$5

if [ -z $(getent group $USER_GID) ]; then
    addgroup --gid $USER_GID "$PRINC_DEP"
    echo "created $PRINC_DEP group on remote host"
fi

if [ $(apt list --installed 2>/dev/null | grep -E '^autofs|nfs-common'| wc -l) -lt 2 ] ; then
    apt update
    apt install nfs-common autofs
fi

if [ -z "$(grep -E '^/home /etc/auto.home' /etc/auto.master)" ]; then
    echo "/home /etc/auto.home" >> /etc/auto.master
fi

if [ -z "(grep -E 'homes.mycompany.lan:/homes/$PRINC_DEP/&$')" ]; then
    echo -e "*\t-fstype=nfs4,rw\thomes.mycompany.lan:/homes/$PRINC_DEP/&" >> /etc/auto.home
    systemctl restart autofs
fi

useradd --shell /bin/bash --password "$PRINC_PWD" --uid $USER_UID --gid $USER_GID "$PRINC_NAME"
