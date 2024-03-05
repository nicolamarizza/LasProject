#!/bin/bash

source ./clear.sh
source ./core.sh

# set drop policies and log prefixes
for chain in $(echo -ne "INPUT\nOUTPUT\nFORWARD"); do
	$IPTABLES -P $chain DROP
done;

############ GENERAL ###############

# allow input from loopback
addRule "-A INPUT -i lo" "GENERAL inp lo" "GENERAL allow input from loopback"

# allow output to loopback
addRule "-A OUTPUT -o lo" "GENERAL out lo" "GENERAL allow output to loopback"

# allow inbound packets from wan to lan with context
addRule "-A INPUT -i $ext_iface -d $lan -m state --state RELATED,ESTABLISHED" "GENERAL inp rel" "GENERAL allow all input related"

# allow all output to wan
addRule "-A OUTPUT -o $ext_iface" "GENERAL out rel" "GENERAL allow router-generated packets to exit to the wan"

############ GENERIC FORWARDING ###############

# enable forwarding
sysctl -w net.ipv4.ip_forward=1

# nat all outbound packets
addRule "-t nat -A POSTROUTING -o $ext_iface -s $lan" "FWD nat outbound" "nat all outbound packets" MASQUERADE

# forward all outbound packets
addRule "-A FORWARD -o $ext_iface -s $lan" "FWD outbound" "forward all outbound packets"

# forward inbound packets with context
addRule "-A FORWARD -i $ext_iface -d $lan -m state --state RELATED,ESTABLISHED" "FWD inbound rel" "forward inbound packets with context"

############ DNS ###############

# allow requests coming from local subnets
addRule "-A INPUT -p udp --dport 53 -s $lan" "DNS req from lan" "allow DNS requests from lan"
addRule "-A INPUT -p tcp --dport 53 -s $lan" "DNS req from lan" "allow DNS requests from lan"
	
# allow forwarding
addRule "-A OUTPUT -p udp --dport 53 -o $ext_iface" "DNS forward req" "allow DNS forwarding to wan"
addRule "-A OUTPUT -p tcp --dport 53 -o $ext_iface" "DNS forward req" "allow DNS forwarding to wan"

# allow replies from forwarders
# source port as well as destination ports might be random
addRule "-A INPUT -p udp -i $ext_iface -m state --state RELATED,ESTABLISHED" "DNS forward reply" "allow DNS replies from wan"
addRule "-A INPUT -p tcp -i $ext_iface -m state --state RELATED,ESTABLISHED" "DNS forward reply" "allow DNS replies from wan"

# allow responses directed to local subnets
# source port might be random
addRule "-A OUTPUT -p udp -d $lan -m state --state RELATED,ESTABLISHED" "DNS repl to lan" "allow DNS replies to lan"
addRule "-A OUTPUT -p tcp -d $lan -m state --state RELATED,ESTABLISHED" "DNS repl to lan" "allow DNS replies to lan"

############ CHRONY ###############

# allow requests from lan
addRule "-A INPUT -p udp --dport 123 -s $lan -m state --state NEW" "NTP req from lan" "allow NTP requests from lan"

# allow replies to lan
addRule "-A OUTPUT -p udp --dport 123 -d $lan -m state --state ESTABLISHED,RELATED" "NTP repl to lan" "allow NTP replies to lan"

# allow requests to wan
addRule "-A OUTPUT -p udp --dport 123 -o $ext_iface -m state --state NEW" "NTP req to wan" "allow NTP requests to wan"

# allow replies from wan
addRule "-A INPUT -p udp --dport 123 -i $ext_iface -m state --state ESTABLISHED,RELATED" "NTP repl from lan" "allow NTP replies from wan"
