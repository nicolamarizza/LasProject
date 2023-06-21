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
