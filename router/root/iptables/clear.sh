#!/bin/bash

IPTABLES=$(which iptables)

# delete rules and zero counters
$IPTABLES -FZ
$IPTABLES -t nat -FZ

# delete user-defined chains
$IPTABLES -X
$IPTABLES -t nat -X
