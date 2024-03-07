#!/bin/bash

source ./variables.sh

for ((i=1; i <= 3; i++)); do

    # dnat inbound packets 192.168.XX.0/24 -> 192.168.X.0/24
    addRule "-t nat -A PREROUTING -d 192.168.$i$i.0/24" \
        "TEST netmap ssh $i" "TEST netmap inbound" \
        "NETMAP --to 192.168.$i.0/24"

done;