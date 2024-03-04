#!/bin/bash

cd /root/utilities/addprinc

read -sp "LDAP admin password: " LDAP_ADMIN_PWD
echo ""
read -p "principal name: " PRINC_NAME
read -p "principal department: " PRINC_DEP
read -sp "principal password: " PRINC_PWD
echo ""
read -p "workstation number: " WS_NO
echo ""

OU_DN="ou=$PRINC_DEP,cn=MYCOMPANY.LAN,cn=KrbContainer,dc=mycompany,dc=lan"
PRINC_FULL_NAME="$PRINC_NAME/$PRINC_DEP@MYCOMPANY.LAN"
ADMIN_DN="cn=admin,dc=mycompany,dc=lan"
PRINC_DN="krbPrincipalName=$PRINC_FULL_NAME,$OU_DN"


# check if department ou exists
ou_search=$(ldapsearch -H ldapi:/// -x -D $ADMIN_DN -w $LDAP_ADMIN_PWD -b $OU_DN | grep 'numEntries')


# create department ou if it doesn't exist
if [ -z "$group_search" ]; then
    echo "creating organizational unit for department $PRINC_DEP"

ldapadd -x -H ldapi:/// -D "cn=admin,dc=mycompany,dc=lan" -w $LDAP_ADMIN_PWD <<EOF
dn: $OU_DN
objectClass: organizationalUnit
ou: $PRINC_DEP
EOF

fi


# create principal in the correct department container
if ! kadmin.local -q "addprinc -pw \"$PRINC_PWD\" -x \"containerdn=$OU_DN\" \"$PRINC_FULL_NAME\""; then
    echo "there was a problem while creating the kerberos principal"
    exit 1
fi


# check if LDAP group exists for that department
group_search=$(ldapsearch -H ldapi:/// -x -D $ADMIN_DN -w $LDAP_ADMIN_PWD -b $OU_DN "(objectClass=groupOfNames)" objectClass | grep 'numEntries')


# create LDAP group for department if it doesn't exist yet
# else just add the principal dn to that group
if [ -z "$group_search" ]; then
    echo "first LDAP group member, creating group"

ldapadd -x -H ldapi:/// -D $ADMIN_DN -w $LDAP_ADMIN_PWD <<EOF
dn: cn=$PRINC_DEP,$OU_DN
objectClass: groupOfNames
cn: $PRINC_DEP
member: $PRINC_DN
EOF
else

ldapmodify -x -H ldapi:/// -D $ADMIN_DN -w $LDAP_ADMIN_PWD <<EOF
dn: cn=$PRINC_DEP,$OU_DN
changetype: modify
add: member
member: $PRINC_DN
EOF
    
    echo "added user to LDAP group"
fi


# create department unix group if it doesn't exist yet
if [ -z "$(getent group $PRINC_DEP | cut -d: -f3)" ]; then
    addgroup $PRINC_DEP
    echo "created unix $PRINC_DEP group"
fi


# create the local unix user
USER_GID=$(getent group $PRINC_DEP | cut -d: -f3)
USER_FULL_NAME="${PRINC_NAME}_$PRINC_DEP"
useradd --no-create-home --gid $USER_GID "$USER_FULL_NAME"
USER_UID=$(getent passwd "$USER_FULL_NAME" | cut -d: -f3)
echo "created local user $USER_FULL_NAME with uid=$USER_UID, gid=$USER_GID"


# create the home share over at homes.mycompany.lan
if ! ssh -i /root/.ssh/id_ed25519 homes.mycompany.lan 'bash -s' -- "$PRINC_NAME" "$PRINC_DEP" $USER_UID $USER_GID < ./addprinc_home.sh; then
    echo "a problem occurred while creating the user home share"
    exit 2
fi


# create the user at the workstation
WS_IP="ws$WS_NO.$PRINC_DEP.mycompany.lan"
if [ -n $WS_IP ]; then

    if ! ssh -i /root/.ssh/id_ed25519 $WS_IP 'bash -s' -- "$PRINC_NAME" "$PRINC_DEP" $USER_UID $USER_GID "$PRINC_PWD" < ./addprinc_remote.sh; then
        echo "a problem occurred while creating the user in the remote host"
        exit 3
    fi

    echo "created user $PRINC_NAME on workstation $WS_IP"
fi
