#!/bin/bash

PRINC_NAME=$1
PRINC_PWD=$2
USER_UID=$3
USER_GID=$4
PRINC_DEP=$5

if [ -z $(getent group $USER_GID) ]; then
    addgroup --gid $USER_GID $PRINC_DEP
    echo "created $PRINC_DEP group on remote host"
fi

useradd --create-home --password $PRINC_PWD --uid $USER_UID --gid $USER_GID $PRINC_NAME
