#!/bin/bash -e

PRINC_NAME=$1
PRINC_DEP=$2
USER_UID=$3
USER_GID=$4

HOME_SHARE="/homes/$PRINC_DEP/$PRINC_NAME"

mkdir -p "$HOME_SHARE"
chmod 700 "$HOME_SHARE"
chown $USER_UID:$USER_GID "$HOME_SHARE"

if [ -z "$(grep -E '^/homes' /etc/exports)" ]; then
    echo -e "/homes\t*(rw,sync,no_subtree_check)" >> /etc/exports
    systemctl restart nfs-server
fi

echo "created home share $HOME_SHARE"
