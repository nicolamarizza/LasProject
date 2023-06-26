#!/bin/bash

PRINC_PWD=$1
PRINC_MAIN=$2
PRINC_INSTANCE=$3
REALM="MYCOMPANY.LAN"
PRINC_UID="$PRINC_MAIN/$PRINC_INSTANCE@$REALM"
BASE_DN="cn=$REALM,cn=krbContainer,dc=mycompany,dc=lan"
MAIN_KEYTAB="/etc/krb5.keytab"

if [ -z "$LDAP_MASTER_PWD" ]; then
    echo '$LDAP_MASTER_PWD variable required'
    exit 1
fi

if [ $# -ne 3 ]; then
    echo "wrong argument number"
    exit 1
fi

echo -ne "Is this principal an employee? y|[n] "
read principal_is_employee;

echo -ne "Add principal to the DIT? y|[n] "
read add_to_dit

if [ "$principal_is_employee" == "y" ]; then
    princ_dn="cn=$PRINC_MAIN,ou=$PRINC_INSTANCE,$BASE_DN"
else
    princ_dn="cn=$PRINC_MAIN,$BASE_DN"
fi


if [ "$add_to_dit" == "y" ]; then

    ldapadd -x -H ldapi:/// -D "cn=admin,dc=mycompany,dc=lan" -w "$LDAP_MASTER_PWD" <<EOF
dn: $princ_dn
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
cn: $PRINC_MAIN
sn: $PRINC_INSTANCE
uid: $PRINC_UID

EOF

    if [ "$principal_is_employee" == "y" ]; then

    ldapmodify -x -H ldapi:/// -D "cn=admin,dc=mycompany,dc=lan" -w "$LDAP_MASTER_PWD" <<EOF
dn: ou=$PRINC_INSTANCE,$BASE_DN
changeType: modify
add: employee
employee: $princ_dn
EOF

    fi
fi


temp_keytab="./${PRINC_MAIN}_${PRINC_INSTANCE}.keytab"

kadmin.local -q "addprinc -pw \"$PRINC_PWD\" -x dn=$princ_dn $PRINC_UID"
kadmin.local -q "ktadd -norandkey -k \"$temp_keytab\" \"$PRINC_MAIN/$PRINC_INSTANCE@$REALM\""
echo -e "rkt \"$temp_keytab\"\nwkt \"$MAIN_KEYTAB\"" | ktutil
