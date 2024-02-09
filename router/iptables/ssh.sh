#!/bin/bash

# allow ssh server requests from wan
ruleAndLog "-A INPUT -p tcp --dport 22 -i $ext_iface" "TEST sshd in" "TEST allow ssh requests from wan"

# allow ssh server replies to wan
ruleAndLog "-A OUTPUT -p tcp --sport 22 -o $ext_iface" "TEST sshd out" "TEST allow ssh replies to wan"

# allow ssh client requests to wan
ruleAndLog "-A OUTPUT -p tcp --dport 22 -o $ext_iface" "TEST sshc out" "TEST allow ssh requests to wan"

# forward inbound ssh req
ruleAndLog "-A FORWARD -p tcp --dport 22 -i $ext_iface -d $local_subnets" "TEST fwd ssh in" "TEST forward inbound ssh requests"

for ((i=1; i <= 3; i++)); do

	# NETMAP inbound ssh req of type 192.168.XX.0/24 -> 192.168.X.0/24
	ruleAndLog "-t nat -A PREROUTING -p tcp --dport 22 -d 192.168.$i$i.0/24" \
		"TEST netmap ssh $i" "TEST netmap inbound ssh for 192.168.$i.0/24" \
		"NETMAP --to 192.168.$i.0/24"

	# forward inbound ssh req
	ruleAndLog "-A FORWARD -p tcp --dport 22 -i $ext_iface -d 192.168.$i.0/24" "TEST fwd ssh in" "TEST forward inbound ssh requests"

	# forward outbound ssh repl
	ruleAndLog "-A FORWARD -p tcp --sport 22 -o $ext_iface -s 192.168.$i.0/24" "TEST fwd ssh out" "TEST forward outbound ssh replies"

done

# allow ssh from kdc to departments
ruleAndLog "-A FORWARD -p tcp --dport 22 -s $servers_dep -d $sales_dep,$customercare_dep" "SSH kdc to dep" "SSH forward requests by kdc to departments"

# allow ssh replies to the kdc
ruleAndLog "-A FORWARD -p tcp --dport 22 -s $sales_dep,$customercare_dep -d $servers_dep -m state --state ESTABLISHED,RELATED" "SSH dep to kdc" "SSH forward replies from departments to kdc"
