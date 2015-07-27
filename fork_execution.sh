#!/bin/bash
# Wasabi tower: 192.168.2.60
# SS-101: 192.168.2.101
# SS-102: 192.168.2.102
# LH-112: 192.168.2.112
# LH-113: 192.168.2.113

# This script is called in the background. It will ssh into the IPaddress passed
#+ as a parameter and execute the wasabiScript.sh program. It then calls SCP to 
#+ copy all of the .csv files from the server back to the host
convertModel(){
	MODNO="$1"

	> folderCheck.txt

	echo "open ftp.box.com" >> folderCheck.txt
	echo "user Tanner.Howell@hgst.com HGSTRoolz!">>folderCheck.txt
	echo "cd /SIT\ Lab\ Team\ Room/Team\ Rooms/Cloud\ Storage\ Team\ Room/Wasabi/temp" >> folderCheck.txt
	echo "ls" >> folderCheck.txt
	echo "bye" >> folderCheck.txt


	# See what folders are already in the wasabi folder on box
	/usr/bin/lftp -f folderCheck.txt 1>wasFolders.txt


	case $MODNO in
		"HUS724040ALE641")	# Mars KP, 4TB model
			MODNAM="Mars-KP"
			;;
		"HUH728060ALE601")	# Aries HC8, 6TB model
			MODNAM="Aries-HC8"
			;;
		"HUH728080ALE601")	# Aries HC8, 8TB model
			MODNAM="Aries-HC8"
			;;
		"HUS726060ALA640")	# Aries HC6, 6TB model
			MODNAM="Aries-HC6"
			;;
		"HUS726060ALE610")	# Aries-KP, 6TB model
			MODNAM="Aries-KP"
			;;
		*)	# If model name isn't in this switch statement, make model string the name
			MODNAM="$MODEL"
			;;
	esac

	NAMTEST=$(/bin/grep $MODNAM wasFolders.txt)

	if [ -z $NAMTEST ]; then
		NEWDIR=1
	else
		NEWDIR=0
	fi

	# Remove text file now that it's no longer needed
	/bin/rm -f wasFolders.txt
	/bin/rm -f folderCheck.txt
}
setupBoxFTP (){
	# Create string name for new folder
	DATE=$(/usr/bin/date +"%m%d%Y-%k%M")
	STR="'$FWREV'_'$NAM'_'$DATE'"
	# Save current directory for later	
	PATH=$(pwd)

	# Cd into wasabiScripts folder
	#cd /home/cyclone/wasabiScripts

	# Create boxFTP.txt file
	>boxFTP.txt
	
	# write ftp commands to boxFTP.txt
	echo "open ftp.box.com" >> boxFTP.txt
	echo "user Tanner.Howell@hgst.com HGSTRoolz!" >> boxFTP.txt

	echo "cd /SIT\ Lab\ Team\ Room/Team\ Rooms/Cloud\ Storage\ Team\ Room/Wasabi/temp" >> boxFTP.txt
	# Check if a new directory has to be made
	if [ $NEWDIR -eq 1 ]; then
		echo "mkdir $MODNAM" >> boxFTP.txt
	fi
	echo "cd $MODNAM" >> boxFTP.txt
	echo "mkdir $STR" >> boxFTP.txt
	echo "cd $STR" >> boxFTP.txt
	echo "mput -d *.csv" >> boxFTP.txt
	echo "bye" >> boxFTP.txt

	# Call lftp to put files onto Box
	cd $PATH
	/usr/bin/lftp -f /home/cyclone/wasabiScripts/boxFTP.txt
}


ADDR="$1"

if [ -z "$ADDR" ]; then
	echo "No address passed, exiting."
	exit 1
fi

# Execute script
ssh root@$ADDR "chmod 755 wasabiScript.sh; ./wasabiScript.sh"

# Get model and FW revision
MOD=($( ssh root@$ADDR "diskdiagtool info all | sed -e 's/ //g' | cut -f2 -d '|' | uniq" ))
FW=($( ssh root@$ADDR "diskdiagtool info all | sed -e 's/ //g' | cut -f4 -d '|' | uniq" ))
MODNAM=""
NEWDIR=0

MODEL=${MOD[1]}
FWREV=${FW[1]}
DATE=$(/bin/date +"%m%d%Y")

# Make sure that all directories exist, make them if they don't
cd /home/cyclone/Test_Results

if [ -z "$MODEL" ]; then
	MODEL=$DATE
fi

if [ -z "$FWREV" ]; then
	FWREV=$DATE
fi

if [ ! -d "$MODEL" ]; then mkdir $MODEL; fi

cd $MODEL

if [ ! -d "$FWREV" ]; then mkdir $FWREV; fi

cd $FWREV

if [ ! -d "SS101" ]; then mkdir SS101; fi

if [ ! -d "SS102" ]; then mkdir SS102; fi

if [ ! -d "LH112" ]; then mkdir LH112; fi

if [ ! -d "LH113" ]; then mkdir LH113; fi

# SCP the .csv files from the server being tested
if [ $ADDR == "192.168.2.101" ]; then
	TEMP="/home/cyclone/Test_Results/$MODEL/$FWREV/SS101"
	cd $TEMP
	mkdir $DATE
	PATH="$TEMP/$DATE"
	/usr/bin/scp root@$ADDR:/root/Random_Workloads/*.csv $PATH
	/usr/bin/scp root@$ADDR:/root/NCQ-Validation/*.csv $PATH
	NAM="SS101"
elif [ $ADDR == "192.168.2.102" ]; then
	TEMP="/home/cyclone/Test_Results/$MODEL/$FWREV/SS102"
	cd $TEMP
	mkdir $DATE
	PATH="$TEMP/$DATE"
	/usr/bin/scp root@$ADDR:/root/Random_Workloads/*.csv $PATH
	/usr/bin/scp root@$ADDR:/root/NCQ-Validation/*.csv $PATH
	NAM="SS102"
elif [ $ADDR == "192.168.2.112" ]; then
	TEMP="/home/cyclone/Test_Results/$MODEL/$FWREV/LH112"
	cd $TEMP
	mkdir $DATE
	PATH="$TEMP/$DATE"
	/usr/bin/scp root@$ADDR:/root/Random_Workloads/*.csv $PATH
	/usr/bin/scp root@$ADDR:/root/NCQ-Validation/*.csv $PATH
	NAM="LH112"
else
	ADDR=192.168.2.113
	TEMP="/home/cyclone/Test_Results/$MODEL/$FWREV/LH113"
	cd $TEMP
	mkdir $DATE
	PATH="$TEMP/$DATE"
	/usr/bin/scp root@$ADDR:/root/Random_Workloads/*.csv $PATH
	/usr/bin/scp root@$ADDR:/root/NCQ-Validation/*.csv $PATH
	NAM="LH113"
fi	

cd $PATH

#convertModel $MODEL
#setupBoxFTP

echo "Testing on the $NAM system has completed"
echo ".csv files are located in /home/cyclone/Test_Results/$MODEL/$FWREV/$NAM"
#echo "Results uploaded to box"
