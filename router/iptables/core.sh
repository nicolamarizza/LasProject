#!/bin/bash

source ./variables.sh
source ./ssh.sh

# nat all outbound packets
ruleAndLog "-t nat -A POSTROUTING -o $ext_iface -s $local_subnets" "FWD nat outbound" "nat all outbound packets" MASQUERADE

for ((i=1; i <= 3; i++)); do

    # dnat inbound packets 192.168.XX.0/24 -> 192.168.X.0/24
    ruleAndLog "-t nat -A PREROUTING -d 192.168.$i$i.0/24" \
        "TEST netmap ssh $i" "TEST netmap inbound" \
        "NETMAP --to 192.168.$i.0/24"

done;