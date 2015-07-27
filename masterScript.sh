#!/bin/bash

# Master script

echo
echo "Enter corresponding number(s) of machine(s) you want to test"
echo "(separated by spaces)"
echo "1....SS-101"
echo "2....SS-102"
echo "3....LH-112"
echo "4....LH-113"
echo "Numbers: "

read -a TEMP
ARR=($(for i in ${TEMP[@]};do echo "$i"; done | sort -n | uniq))

# Save IP addresses as variables
TOWER="192.168.2.60"
SS101="192.168.2.101"
SS102="192.168.2.102"
LH112="192.168.2.112"
LH113="192.168.2.113"

for i in ${ARR[@]}; do
	if [ $i -eq 1 ]; then
		echo "Copying to SS-101 and beginning execution"
		scp wasabiScript.sh root@$SS101:/root
		cd /
		scp -r Random_Workloads root@$SS101:/root
		scp -r NCQ-Validation root@$SS101:/root
		cd /home/cyclone/wasabiScripts
		./fork_execution.sh $SS101 &

	elif [ $i -eq 2 ]; then
		echo "Copying to SS-102 and beginning execution"
		scp wasabiScript.sh root@$SS102:/root
		cd /
		scp -r Random_Workloads root@$SS102:/root
		scp -r NCQ-Validation root@$SS102:/root
		cd /home/cyclone/wasabiScripts
		./fork_execution.sh $SS102 &

	elif [ $i -eq 3 ]; then
		echo "Copying to LH-112 and beginning execution"
		scp wasabiScript.sh root@$LH112:/root
		cd /
		scp -r Random_Workloads root@$LH112:/root
		scp -r NCQ-Validation root@$LH112:/root
		cd /home/cyclone/wasabiScripts
		./fork_execution.sh $LH112 &

	elif [ $i -eq 4 ]; then
		echo "Copying to LH-113 and beginning execution"
		scp wasabiScript.sh root@$LH113:/root
		cd /
		scp -r Random_Workloads root@$LH113:/root
		scp -r NCQ-Validation root@$LH113:/root
		cd /home/cyclone/wasabiScripts
		./fork_execution.sh $LH113 &

	else
		echo "Something went wrong"
		exit 1
	fi
done

exit 0
