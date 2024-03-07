#!/bin/bash

IPTABLES=$(which iptables)

lan="192.168.0.0/16"
admin="192.168.1.2"
homes="192.168.1.6"
servers_subnet="192.168.1.0/24"
sales_subnet="192.168.2.0/24"
customercare_subnet="192.168.3.0/24"

departments="$sales_subnet,$customercare_subnet"

ext_iface=ens0

function addRule() {
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
