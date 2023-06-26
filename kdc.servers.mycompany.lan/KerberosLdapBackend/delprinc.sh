#!/bin/bash

PRINC_MAIN=$1
PRINC_INSTANCE=$2
REALM=MYCOMPANY.LAN
PRINC_UID="$PRINC_MAIN/$PRINC_INSTANCE@$REALM"
BASE_DN="cn=$REALM,cn=krbContainer,dc=mycompany,dc=lan"
MAIN_KEYTAB="/etc/krb5.keytab"

if [ -z "$LDAP_MASTER_PWD" ]; then
    echo '$LDAP_MASTER_PWD variable required'
    exit 1
fi

if [ $# -ne 2 ]; then
    echo "wrong argument number"
    exit 1
fi

echo -ne "Delete principal from the DIT? [y|n]"
read DEL_FROM_DIT

if [ $# -eq 3 ]; then
    echo -ne "is principal under ou=\"$PRINC_INSTANCE\"? [y|n]"
    read INSTANCE_IS_OU;
fi

if [ "$INSTANCE_IS_OU" == "y" ]; then
    PRINC_DN="cn=$PRINC_MAIN,ou=\"$PRINC_INSTANCE\",$BASE_DN"

    ldapmodify -x -H ldapi:/// -D "cn=admin,dc=mycompany,dc=lan" -w "$LDAP_MASTER_PWD" <<EOF
dn: ou=$PRINC_INSTANCE,$BASE_DN
changeType: modify
delete: employee
employee: $princ_dn
EOF

else
    PRINC_DN="cn=$PRINC_MAIN,$BASE_DN"
fi


if [ "$DEL_FROM_DIT" == "y" ]; then
    ldapdelete -x -H ldapi:/// -D "cn=admin,dc=mycompany,dc=lan" -w "$LDAP_MASTER_PWD" "$PRINC_DN"
fi

kadmin.local -q "ktremove -k $MAIN_KEYTAB -q \"$PRINC_UID\""
kadmin.local -q "delete_principal -force \"$PRINC_UID\""
