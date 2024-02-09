#!/bin/bash

source ./variables.sh
source ./reset.sh

iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT

for ((i=1; i <= 3; i++)); do

	# NETMAP inbound ssh req of type 192.168.XX.0/24 -> 192.168.X.0/24
	ruleAndLog "-t nat -A PREROUTING -d 192.168.$i$i.0/24" \
		"TEST netmap ssh $i" "TEST netmap inbound 192.168.$i.0/24" \
		"NETMAP --to 192.168.$i.0/24"

done