#!/bin/bash

for ((i=1; i <= 3; i++)); do

	# NETMAP inbound ssh req of type 192.168.XX.0/24 -> 192.168.X.0/24
	addRule "-t nat -A PREROUTING -d 192.168.$i$i.0/24" \
		"TEST netmap ssh $i" "TEST netmap inbound 192.168.$i.0/24" \
		"NETMAP --to 192.168.$i.0/24"

done

# forward inbound ssh
addRule "-A FORWARD -i $ext_iface -d $lan -p tcp --dport 22" "FWD inbound ssh" "forward inbound ssh"

# allow ssh connections to router
addRule "-A INPUT -i $ext_iface -p tcp --dport 22" "SSH WAN to router" "allow ssh connections to router"
