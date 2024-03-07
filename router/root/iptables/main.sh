#!/bin/bash

source ./clear.sh
source ./core.sh

# for testing only
#source ./testing.sh

# set drop policies and log prefixes
$IPTABLES -P INPUT DROP
$IPTABLES -P OUTPUT DROP
$IPTABLES -P FORWARD DROP

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

############ WEBSERVER ###############

# allow HTTP requests from departments to servers
addRule "-A FORWARD -p tcp --dport 80 -s $departments -d $servers_subnet" "HTTP req" "forward dep HTTP to servers"

# allow HTTP replies from servers to departments
addRule "-A FORWARD -p tcp --sport 80 -s $servers_subnet -d $departments" "HTTP rep" "forward servers HTTP to dep"

############ KERBEROS ###############

# allow TGS_REQ from departments to servers
addRule "-A FORWARD -p udp --dport 88 -s $departments -d $servers_subnet" "TGS_REQ" "forward TGS_REQ from dep"

# allow TGS_REP from servers to departments
addRule "-A FORWARD -p udp --sport 88 -s $servers_subnet -d $departments" "TGS_REP" "forward TGS_REP to dep"

# allow KPASSWD request from departments
addRule "-A FORWARD -p tcp --dport 464 -s $departments -d $servers_subnet" "KPASSWD" "forward KPASSWD from dep"

# allow KPASSWD request from departments
addRule "-A FORWARD -p tcp --sport 464 -s $servers_subnet -d $departments -m state --state ESTABLISHED,RELATED" "KPASSWD" "forward KPASSWD from dep"

############ SSH ###############

# forward admin ssh to workstations
addRule "-A FORWARD -p tcp --dport 22 -s $admin -d $departments " "SSH admin to ws" "forward admin ssh to workstations"

# forward ssh workstations replies to admin
addRule "-A FORWARD -p tcp --sport 22 -s $departments -d $admin -m state --state ESTABLISHED,RELATED" "SSH repl to admin" "forward ssh workstations replies to admin"

############ NFS ###############

# forward NFS dep to homes
addRule "-A FORWARD -p tcp --dport 2049 -s $departments -d $homes " "NFS dep to homes" "forward NFS dep to homes"

# forward NFS homes to dep
addRule "-A FORWARD -p tcp --sport 2049 -s $homes -d $departments " "NFS homes to dep" "forward NFS homes to dep"
