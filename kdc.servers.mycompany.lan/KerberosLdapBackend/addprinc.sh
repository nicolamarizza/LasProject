#!/bin/bash

PRINC_NAME=$1
PRINC_DEP=$2
PRINC_PWD=$3
BASE_DN="cn=MYCOMPANY.LAN,cn=KrbContainer,dc=mycompany,dc=lan"

kadmin.local -q "addprinc -pw \"$PRINC_PWD\" -x dn=ou=$PRINC_DEP,$BASE_DN $PRINC_NAME/$PRINC_DEP@MYCOMPANY.LAN"
