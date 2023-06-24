#!/bin/bash

source ./reset.sh
source ./core.sh

# set drop policies and log prefixes
for chain in $(echo -ne "INPUT\nOUTPUT\nFORWARD"); do
	$IPTABLES -P $chain DROP
done;


############ TESTING ###############
host_network="192.168.100.0/24"

# allow inbound packets from wan
ruleAndLog "-A FORWARD -i $ext_iface -d $local_subnets" "TEST anything inb" "TEST forward anything inbound"

# allow icmp ping request from lan
ruleAndLog "-A INPUT ! -i $ext_iface -p icmp --icmp-type echo-request" "TEST ping req" "TEST allow icmp ping requests from lan"

# allow icmp ping reply to lan
ruleAndLog "-A OUTPUT ! -o $ext_iface -p icmp --icmp-type echo-reply" "TEST ping repl" "TEST allow icmp ping replies to lan"

# allow icmp ping request to lan
ruleAndLog "-A OUTPUT ! -o $ext_iface -p icmp --icmp-type echo-request" "TEST ping req" "TEST allow icmp ping requests to lan"

# allow icmp ping reply from lan
ruleAndLog "-A INPUT ! -i $ext_iface -p icmp --icmp-type echo-reply" "TEST ping repl" "TEST allow icmp ping replies from lan"

# allow web requests from host network
ruleAndLog "-A FORWARD -s $host_network -d 192.168.3.5 -p tcp --dport 80" "TEST web req" "TEST allow web requests from host network"

# allow web replies to host network
ruleAndLog "-A FORWARD -o $ext_iface -s 192.168.3.5" "TEST web req" "TEST allow web replies to host network"

############ GENERAL ###############

# allow input from loopback
ruleAndLog "-A INPUT -i lo" "GENERAL inp lo" "GENERAL allow input from loopback"

# allow output to loopback
ruleAndLog "-A OUTPUT -o lo" "GENERAL out lo" "GENERAL allow output to loopback"

# allow inbound packets from wan to lan with context
ruleAndLog "-A INPUT -i $ext_iface -d $local_subnets -m state --state RELATED,ESTABLISHED" "GENERAL inp rel" "GENERAL allow all input related"

# allow all output to wan
ruleAndLog "-A OUTPUT -o $ext_iface" "GENERAL out rel" "GENERAL allow router-generated packets to exit to the wan"

############ FORWARDING ###############

# enable forwarding
sysctl -w net.ipv4.ip_forward=1

# allow all outbound packets
ruleAndLog "-A FORWARD -o $ext_iface -s $local_subnets" "FWD outbound" "forward all outbound packets"

# allow inbound packets with context
ruleAndLog "-A FORWARD -i $ext_iface -d $local_subnets -m state --state RELATED,ESTABLISHED" "FWD inbound rel" "forward inbound packets with context"

############ DNS ###############

# allow requests coming from local subnets
ruleAndLog "-A INPUT -p udp --dport 53 -s $local_subnets" "DNS req from lan" "allow DNS requests from lan"
ruleAndLog "-A INPUT -p tcp --dport 53 -s $local_subnets" "DNS req from lan" "allow DNS requests from lan"
	
# allow forwarding
ruleAndLog "-A OUTPUT -p udp --dport 53 -o $ext_iface" "DNS forward req" "allow DNS forwarding to wan"
ruleAndLog "-A OUTPUT -p tcp --dport 53 -o $ext_iface" "DNS forward req" "allow DNS forwarding to wan"

# allow replies from forwarders
# source port as well as destination ports might be random
ruleAndLog "-A INPUT -p udp -i $ext_iface -m state --state RELATED,ESTABLISHED" "DNS forward reply" "allow DNS replies from wan"
ruleAndLog "-A INPUT -p tcp -i $ext_iface -m state --state RELATED,ESTABLISHED" "DNS forward reply" "allow DNS replies from wan"

# allow responses directed to local subnets
# source port might be random
ruleAndLog "-A OUTPUT -p udp -d $local_subnets -m state --state RELATED,ESTABLISHED" "DNS repl to lan" "allow DNS replies to lan"
ruleAndLog "-A OUTPUT -p tcp -d $local_subnets -m state --state RELATED,ESTABLISHED" "DNS repl to lan" "allow DNS replies to lan"

############ CHRONY ###############

# allow requests from lan
ruleAndLog "-A INPUT -p udp --dport 123 -s $local_subnets -m state --state NEW" "NTP req from lan" "allow NTP requests from lan"

# allow replies to lan
ruleAndLog "-A OUTPUT -p udp --dport 123 -d $local_subnets -m state --state ESTABLISHED,RELATED" "NTP repl to lan" "allow NTP replies to lan"

# allow requests to wan
ruleAndLog "-A OUTPUT -p udp --dport 123 -o $ext_iface -m state --state NEW" "NTP req to wan" "allow NTP requests to wan"

# allow replies from wan
ruleAndLog "-A INPUT -p udp --dport 123 -i $ext_iface -m state --state ESTABLISHED,RELATED" "NTP repl from lan" "allow NTP replies from wan"
