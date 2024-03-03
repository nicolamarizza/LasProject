#!/bin/bash

read -p "LDAP admin password: " LDAP_ADMIN_PWD

read -p "principal name: " PRINC_NAME
read -p "principal department: " PRINC_DEP
read -p "principal password: " PRINC_PWD

BASE_DN="ou=$PRINC_DEP,cn=MYCOMPANY.LAN,cn=KrbContainer,dc=mycompany,dc=lan"
PRINC_FULL_NAME="$PRINC_NAME/$PRINC_DEP@MYCOMPANY.LAN"
ADMIN_DN="cn=admin,dc=mycompany,dc=lan"
PRINC_FULL_DN="krbPrincipalName=$PRINC_FULL_NAME,$BASE_DN"

if ! kadmin.local -q "addprinc -pw \"$PRINC_PWD\" -x \"containerdn=$BASE_DN\" \"$PRINC_FULL_NAME\""; then
    echo "there was a problem while creating the kerberos principal"
    exit 1
fi

echo "created kerberos principal"

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

echo "created kerberos principal"

if [ -z "$(getent group $PRINC_DEP | cut -d: -f3)" ]; then
    addgroup $PRINC_DEP
    echo "created unix $PRINC_DEP group"
fi

USER_GID=$(getent group $PRINC_DEP | cut -d: -f3)
USER_FULL_NAME=${PRINC_NAME}_$PRINC_DEP

useradd --no-create-home --password $PRINC_PWD --gid $USER_GID $USER_FULL_NAME
echo "created unix user $USER_FULL_NAME"

read -p "insert host ip in which to create user via ssh (enter to ignore): " SSH_IP

if [ -n $SSH_IP ]; then
    USER_UID=$(getent passwd $USER_FULL_NAME | cut -d: -f4)

    if ! ssh -i /root/.ssh/id_ed25519 $SSH_IP 'bash -s' -- $PRINC_NAME $PRINC_PWD $USER_UID $USER_GID $PRINC_DEP < ./addprinc_remote.sh; then
        echo "a problem occurred while creating the user in the remote host"
        exit 2
    fi

    echo "user successfully created on remote host"
fi
