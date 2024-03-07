#!/bin/bash

IPTABLES=$(which iptables)

$IPTABLES -F	# delete rules
$IPTABLES -X	# delete user-defined chains
$IPTABLES -Z	# zero the counters

for chain in $(echo -ne "PREROUTING\nINPUT\nOUTPUT\nPOSTROUTING"); do
	$IPTABLES -t nat -F
	$IPTABLES -t nat -X
done;
