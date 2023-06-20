#!/bin/bash

IPTABLES=$(which iptables)

sales_dep="192.168.4.0/24"
customercare_dep="192.168.5.0/24"
servers_dep="192.168.3.0/24"
local_subnets="$servers_dep,$sales_dep,$customercare_dep"
local="127.0.0.0/8"
ext_iface="$(getiface 100)"

function ruleAndLog() {
	match="$1"
	prefix="$2"
	comment="$3"
	target="$4"

	if [ -z "$target" ]; then
		target=ACCEPT
	fi

	$IPTABLES $match -m comment --comment="$comment" -j LOG --log-prefix="[IPTABLES-$prefix] "
	$IPTABLES $match -m comment --comment="$comment" -j $target
}

$IPTABLES -F	# delete rules
$IPTABLES -X	# delete user-defined chains
$IPTABLES -Z	# zero the counters

for chain in $(echo -ne "PREROUTING\nINPUT\nOUTPUT\nPOSTROUTING"); do
	$IPTABLES -t nat -F
	$IPTABLES -t nat -X
done;

# set drop policies and log prefixes
for chain in $(echo -ne "INPUT\nOUTPUT\nFORWARD"); do
	$IPTABLES -P $chain DROP
done;



############ TESTING ###############

# allow ssh server requests from wan
ruleAndLog "-A INPUT -p tcp --dport 22 -i $ext_iface" "TEST sshd in" "TEST allow ssh requests from wan"

# allow ssh server replies to wan
ruleAndLog "-A OUTPUT -p tcp --sport 22 -o $ext_iface" "TEST sshd out" "TEST allow ssh replies to wan"

# allow ssh client requests to wan
ruleAndLog "-A OUTPUT -p tcp --dport 22 -o $ext_iface" "TEST sshc out" "TEST allow ssh requests to wan"

# allow inbound packets from wan
ruleAndLog "-A FORWARD -i $ext_iface -d $local_subnets" "TEST anything inb" "TEST forward anything inbound"

# allow icmp ping request from lan
ruleAndLog "-A INPUT ! -i $ext_iface -p icmp --icmp-type echo-request" "TEST ping req" "TEST allow icmp ping requests from lan"

# allow icmp ping reply to lan
ruleAndLog "-A OUTPUT ! -o $ext_iface -p icmp --icmp-type echo-reply" "TEST ping repl" "TEST allow icmp ping replies to lan"

############ GENERAL ###############

# allow everything coming from loopback
ruleAndLog "-A INPUT -s $local" "GENERAL inp lo" "GENERAL allow input from loopback"

# allow inbound packets from wan to lan with context
ruleAndLog "-A INPUT -i $ext_iface -d $local_subnets -m state --state RELATED,ESTABLISHED" "GENERAL inp rel" "GENERAL allow all input related"

############ FORWARDING ###############

# enable forwarding
sysctl -w net.ipv4.ip_forward=1

# nat all outbound packets
ruleAndLog "-t nat -A POSTROUTING -o $ext_iface -s $local_subnets" "FWD nat outbound" "nat all outbound packets" MASQUERADE

# allow all outbound packets
ruleAndLog "-A FORWARD -o $ext_iface -s $local_subnets" "FWD outbound" "forward all outbound packets"

# allow inbound packets with context
ruleAndLog "-A FORWARD -i $ext_iface -d $local_subnets -m state --state RELATED,ESTABLISHED" "FWD inbound rel" "forward inbound packets with context"

############ DNS ###############

# allow requests coming from local subnets
ruleAndLog "-A INPUT -p udp --dport 53 -s $local,$local_subnets" "DNS req from lan" "allow DNS requests from lan"
ruleAndLog "-A INPUT -p tcp --dport 53 -s $local,$local_subnets" "DNS req from lan" "allow DNS requests from lan"
	
# allow forwarding
ruleAndLog "-A OUTPUT -p udp --dport 53 -o $ext_iface" "DNS forward req" "allow DNS forwarding to wan"
ruleAndLog "-A OUTPUT -p tcp --dport 53 -o $ext_iface" "DNS forward req" "allow DNS forwarding to wan"

# allow replies from forwarders
# source port as well as destination ports might be random
ruleAndLog "-A INPUT -p udp -m state --state RELATED,ESTABLISHED -i $ext_iface" "DNS forward reply" "allow DNS replies from wan"
ruleAndLog "-A INPUT -p tcp -m state --state RELATED,ESTABLISHED -i $ext_iface" "DNS forward reply" "allow DNS replies from wan"

# allow responses directed to local subnets
# source port might be random
ruleAndLog "-A OUTPUT -p udp -d $local,$local_subnets -m state --state RELATED,ESTABLISHED" "DNS resp to lan" "allow DNS replies to lan"
ruleAndLog "-A OUTPUT -p tcp -d $local,$local_subnets -m state --state RELATED,ESTABLISHED" "DNS resp to lan" "allow DNS replies to lan"
