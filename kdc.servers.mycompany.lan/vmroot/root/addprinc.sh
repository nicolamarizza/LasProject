#!/bin/bash

read -p "LDAP admin password:" LDAP_ADMIN_PWD

read -p "principal name:" PRINC_NAME
read -p "principal department:" PRINC_DEP
read -p "principal password:" PRINC_PWD

BASE_DN="ou=$PRINC_DEP,cn=MYCOMPANY.LAN,cn=KrbContainer,dc=mycompany,dc=lan"
PRINC_FULL_NAME="$PRINC_NAME/$PRINC_DEP@MYCOMPANY.LAN"
ADMIN_DN="cn=admin,dc=mycompany,dc=lan"
PRINC_FULL_DN="krbPrincipalName=$PRINC_FULL_NAME,$BASE_DN"

kadmin.local -q "addprinc -pw \"$PRINC_PWD\" -x \"containerdn=$BASE_DN\" \"$PRINC_FULL_NAME\""

group_search=$(ldapsearch -H ldapi:/// -x -D $ADMIN_DN -w $LDAP_ADMIN_PWD -b $BASE_DN "(objectClass=groupOfNames)" objectClass | grep 'numEntries')

if [ -z "$group_search" ]; then
    echo "creating group for the first user"

ldapadd -x -H ldapi:/// -D $ADMIN_DN -w $LDAP_ADMIN_PWD <<EOF
dn: cn=$PRINC_DEP,ou=$PRINC_DEP,cn=MYCOMPANY.LAN,cn=krbContainer,dc=mycompany,dc=lan
objectClass: groupOfNames
cn: $PRINC_DEP
member: $PRINC_FULL_DN
EOF
else
    echo "adding user to group"

ldapmodify -x -H ldapi:/// -D $ADMIN_DN -w $LDAP_ADMIN_PWD <<EOF
dn: cn=$PRINC_DEP,ou=$PRINC_DEP,cn=MYCOMPANY.LAN,cn=krbContainer,dc=mycompany,dc=lan
changetype: modify
add: member
member: $PRINC_FULL_DN
EOF
fi
