#!/bin/bash -xe

PRINC_NAME=$1
PRINC_DEP=$2
PRINC_PWD=$3
BASE_DN=cn=MYCOMPANY.LAN,cn=krbContainer,dc=mycompany,dc=lan

if [ $# -ne 3 ]; then
    echo "wrong argument number"
    exit
fi

echo -ne "Add principal to the DIT? [y|n]"
read add

if [ $add == "y" ]; then

    ldapadd -x -H ldapi:/// -D "cn=admin,dc=mycompany,dc=lan" -w $LDAP_MASTER_PWD <<EOF
dn: cn=$PRINC_NAME,ou=$PRINC_DEP,$BASE_DN
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
cn: $PRINC_NAME
sn: $PRINC_DEP

EOF

fi
kadmin.local -q "addprinc -pw \"$PRINC_PWD\" -x dn=cn=$PRINC_NAME,ou=$PRINC_DEP,$BASE_DN $PRINC_NAME/$PRINC_DEP@MYCOMPANY.LAN"
