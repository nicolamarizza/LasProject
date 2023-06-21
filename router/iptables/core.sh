#!/bin/bash

source ./variables.sh
source ./ssh.sh

# nat all outbound packets
ruleAndLog "-t nat -A POSTROUTING -o $ext_iface -s $local_subnets" "FWD nat outbound" "nat all outbound packets" MASQUERADE
