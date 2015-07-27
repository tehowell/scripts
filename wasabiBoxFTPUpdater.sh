#!/bin/bash

addModel () {
	NEWNO="$1"
	NEWNAM="$2"

	# Format for statement to be inserted:
	#
	# "HUS724040ALE641")	# Mars KP, 4TB model
	#	 MODNAM="Mars-KP"
	# 	 ;;

	# Format strings
	A='"'
	A=$A$NEWNO
	A=$A'")'

	B="MODNAM=$NEWNAM"
	C=";;"

	# Check to make sure model isn't already in automation
	EXISTS=$( grep "$A" fork_execution.sh | wc -l )

	if [ $EXISTS -gt 0 ]; then
		echo "Entry already exists!"
		echo "Entry not added"
	
	else	
		# Insert entry into fork_execution file
		sed -i "$(grep -n 'case $MODNO in' fork_execution.sh | cut -f1 -d ':')a\			$C\\" fork_execution.sh
		sed -i "$(grep -n 'case $MODNO in' fork_execution.sh | cut -f1 -d ':')a\			$B\\" fork_execution.sh
		sed -i "$(grep -n 'case $MODNO in' fork_execution.sh | cut -f1 -d ':')a\		$A\\" fork_execution.sh
		echo "New entry for $NEWNAM has been added"
	fi
}

changeUsr () {
	# New username and password
	USRNAM="$1"
	USRPSWD="$2"

	# Create the user login string
	USRSTR="user $USRNAM $USRPSWD"

	CHECKSTR='echo "'$USRSTR'">>folderCheck.txt'
	FTPSTR='echo "'$USRSTR'" >> boxFTP.txt'

	# Replace the old login with the new one
	sed -i "0,/.*user*./ s/.*user.*/	$CHECKSTR/" fork_execution.sh
	sed -i "0,/.*user*./! s/.*user.*/	$FTPSTR/" fork_execution.sh
	
	echo "Login updated!"
}

echo
echo "This script is for setting up the box upload automation"
echo "This version of it is for wasabi testing only"
echo
echo "Enter the command you wish to execute:"
echo 
echo "add [ModelNo] [ModelNam]"
echo "		(Adds a new model number and model name to the automation)"
echo "usr [HGST Email] [Box Password]"
echo "		(Change user for login. MUST HAVE EXTERNAL PASSWORD)"
echo "exit"
echo "		(Exits script)"

while [ true ]; do
	printf "Command: "
	read -a COMMAND

	if [ ${COMMAND[0]} == "add" ]; then
		
		if [ -z ${COMMAND[1]} ]; then
			echo "Invalid model number. Try again"

		elif [ -z ${COMMAND[2]} ]; then
			echo "Invalid model name. Try again."
		
		else
			addModel ${COMMAND[1]} ${COMMAND[2]}
		fi

	elif [ ${COMMAND[0]} = "usr" ]; then

		if [ -z ${COMMAND[1]} ]; then
			echo "Invalid username. Try again."

		elif [ -z ${COMMAND[2]} ]; then
			echo "Invalid username password. Try again."

		else
			changeUsr ${COMMAND[1]} ${COMMAND[2]}
		fi

	elif [ ${COMMAND[0]} == "exit" ]; then
		exit 0
	
	else
		echo "Invalid command. Try again."
	fi

	declare -a COMMAND=()
done
