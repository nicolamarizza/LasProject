#!/bin/bash

echo -ne "fetch main.sh from source? [y|n]:"
read fetch

if [ $fetch == "y" ]; then
	scp nick@192.168.100.11:/home/nick/University/Terzo_Anno/Secondo_Semestre/AmministrazioneSistemi/Project/LasProject/router/iptables/main.sh main.sh
fi

if ! bash -xe ./main.sh > iptables.err 2>&1; then
	echo "iptables error! check iptables.err"

	./reset.sh
	./core.sh
	
	# open all chains
	for chain in $(echo -ne "INPUT\nOUTPUT\nFORWARD"); do
		$IPTABLES -P $chain ACCEPT
	done;
fi
