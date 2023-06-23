#!/bin/bash -xe

PRINC_PWD=$1
PRINC_NAME=$2
PRINC_INSTANCE=$3
REALM=MYCOMPANY.LAN
PRINC_UID="$PRINC_NAME/$PRINC_INSTANCE@$REALM"
BASE_DN="cn=$REALM,cn=krbContainer,dc=mycompany,dc=lan"

if [ -z "$LDAP_MASTER_PWD" ]; then
    echo '$LDAP_MASTER_PWD variable required'
    exit 1
fi

if [ $# -ne 3 ]; then
    echo "wrong argument number"
    exit 1
fi

echo -ne "Add principal to the DIT? [y|n]"
read ADD_TO_DIT

if [ $# -eq 3 ]; then
    echo -ne "put principal under ou=$PRINC_INSTANCE? [y|n]"
    read INSTANCE_IS_OU;
fi

if [ "$INSTANCE_IS_OU" -eq "y" ]; then
    PRINC_DN="cn=$PRINC_NAME,ou=$PRINC_INSTANCE,$BASE_DN"
else
    PRINC_DN="cn=$PRINC_NAME,$BASE_DN"
fi


if [ "$ADD_TO_DIT" == "y" ]; then

    ldapadd -x -H ldapi:/// -D "cn=admin,dc=mycompany,dc=lan" -w "$LDAP_MASTER_PWD" <<EOF
dn: $PRINC_DN
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
cn: $PRINC_NAME
sn: $PRINC_INSTANCE
uid: $PRINC_UID

EOF

fi

kadmin.local -q "addprinc -pw \"$PRINC_PWD\" -x dn=$PRINC_DN $PRINC_UID"
