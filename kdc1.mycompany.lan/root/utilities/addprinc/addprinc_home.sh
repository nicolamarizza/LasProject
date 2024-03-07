#!/bin/bash

PRINC_NAME=$1
PRINC_DEP=$2
USER_UID=$3
USER_GID=$4

HOME_SHARE="/homes/$PRINC_DEP/$PRINC_NAME"

mkdir -p "$HOME_SHARE"
chmod 700 "$HOME_SHARE"
chown $USER_UID:$USER_GID "$HOME_SHARE"

# 25GiB: 6553600 blocks
# 90% of 25GiB: 5898240 blocks
setquota -u $USER_UID 5898240 6553600 0 0 /homes/$PRINC_DEP

echo "created home share $HOME_SHARE"
