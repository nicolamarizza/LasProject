#!/bin/bash

read -sp "LDAP admin password: " LDAP_ADMIN_PWD
echo ""
read -p "principal name: " PRINC_NAME
read -p "principal department: " PRINC_DEP
read -p "workstation number: " WS_NO
echo ""

OU_DN="ou=$PRINC_DEP,cn=MYCOMPANY.LAN,cn=KrbContainer,dc=mycompany,dc=lan"
PRINC_FULL_NAME="$PRINC_NAME/$PRINC_DEP@MYCOMPANY.LAN"
ADMIN_DN="cn=admin,dc=mycompany,dc=lan"
LDAP_GROUP_DN="cn=$PRINC_DEP,$OU_DN"
PRINC_DN="krbPrincipalName=$PRINC_FULL_NAME,$OU_DN"


# delete principal
kadmin.local delprinc $PRINC_FULL_NAME
echo "deleted principal $PRINC_FULL_NAME"


# if LDAP group only contains this principal, delete organizational unit
if [ $(ldapsearch -H ldapi:/// -x -D $ADMIN_DN -w $LDAP_ADMIN_PWD -b $LDAP_GROUP_DN member | grep -E '^member:' | wc -l) -eq 1 ]; then
    ldapdelete -r -x -H ldapi:/// -D $ADMIN_DN -w $LDAP_ADMIN_PWD "$OU_DN"
    echo "$PRINC_FULL_NAME was the last member of LDAP group $PRINC_DEP, organizational unit removed"
else 
# remove principal from department group
ldapmodify -x -H ldapi:/// -D $ADMIN_DN -w $LDAP_ADMIN_PWD <<EOF
dn: $LDAP_GROUP_DN
delete: member
member: $PRINC_DN
EOF
echo "removed principal $PRINC_FULL_NAME from LDAP group"
fi

# delete local user
deluser ${PRINC_NAME}_$PRINC_DEP > /dev/null 2>&1
echo "deleted local user ${PRINC_NAME}_$PRINC_DEP"

# delete user from workstation
ssh root@ws$WS_NO.$PRINC_DEP.mycompany.lan "deluser --force $PRINC_NAME > /dev/null 2>&1"
if [ $? -eq 0 ]; then
    echo "deleted user $PRINC_NAME from workstation"
else
    echo "an exception occurred while deleting user $PRINC_NAME from workstation"
fi

# delete home share
ssh root@homes.mycompany.lan "rm -r /homes/$PRINC_DEP/$PRINC_NAME"
echo "deleted home share /homes/$PRINC_DEP/$PRINC_NAME"
