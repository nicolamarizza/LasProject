#!/bin/bash -e

PRINC_NAME=$1
PRINC_DEP=$2
USER_UID=$3
USER_GID=$4

HOME_SHARE="/homes/$PRINC_DEP/$PRINC_NAME"

mkdir -p "$HOME_SHARE"
chmod 700 "$HOME_SHARE"
chown $USER_UID:$USER_GID "$HOME_SHARE"

echo "created home share $HOME_SHARE"
