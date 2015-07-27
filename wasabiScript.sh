#!/bin/sh

getData() {
	# Temporary arrays for testing
	# COMMENT OUT WHEN PROGRAM FINISHED
	#DISK=($( grep '|' diskdiagtool.txt | sed -e 's/ //g' | cut -f1 -d '|'))
	#MODEL=($( grep '|' diskdiagtool.txt | sed -e 's/ //g' | cut -f2 -d '|' | uniq))
	#SERIAL=($( grep '|' diskdiagtool.txt | sed -e 's/ //g' | cut -f3 -d '|'))
	#FWREV=($( grep '|' diskdiagtool.txt | sed -e 's/ //g' | cut -f4 -d '|' | uniq))

	# COMMENT BACK IN WHEN PROGRAM FINISHED
	DISK=($( diskdiagtool info all | sed -e 's/ //g' | cut -f1 -d '|' ))
	MODEL=($( diskdiagtool info all | sed -e 's/ //g' | cut -f2 -d '|' ))
	SERIAL=($( diskdiagtool info all | sed -e 's/ //g' | cut -f3 -d '|' ))
	FWREV=($( diskdiagtool info all | sed -e 's/ //g' | cut -f4 -d '|' ))
	
	unset DISK[0]
	unset MODEL[0]
	unset SERIAL[0]
	unset FWREV[0]

	DISK=( "${DISK[@]}" )
	MODEL=( "${MODEL[@]}" )
	SERIAL=( "${SERIAL[@]}" )
	FWREV=( "${FWREV[@]}" )
}

runTest() {
	# Retrieve passed parameters
	SIZE="${1}"
	shift
	TEMP="${@}"

	# Sort array of tests in reverse order. 
	TESTS=($(for j in ${TEMP[@]}; do echo "$j"; done | sort -dr))

	#echo " Currently testing: $SIZE"

	# Name output summary file
	SUMMARY=""
	SUMMARY="${MODEL[1]}_${FWREV[1]}$SIZE"
	# Initialize headers for summary file
	declare -a HEADERS=("Drive," "Serial Number," "Test Type," "Read IOPS," "Write IOPS," "Total IOPS," "99.99% Tail Latency Read (ms)," "99.99% Tail Latency Write (ms),")

	# Initialize arrays for data
	declare -a DRVNAM=('sda' 'sdb' 'sdc' 'sdd' 'sde' 'sdf' 'sdg' 'sdh' 'sdi' 'sdj' 'sdk' 'sdl' 'sdm' 'sdn')	

	# Initialize output file
	> $SUMMARY.csv
		
	# Write headers to output file
	echo ${HEADERS[@]} >> $SUMMARY.csv

	for i in ${TESTS[@]}; do
	
		# Name Output File
		OUTPUT=""	
		OUTPUT=$(basename $i .fio_conf)
		OUTPUT="$OUTPUT.fio_out"

		# Run FIO on each config file
		# COMMENT BACK IN WHEN TESTING CODE
		fio --output=$OUTPUT --minimal $i

		READFIL=""
		READFIL="$OUTPUT"

		declare -a READIO=()
		declare -a WRITEIO=()
		declare -a TOTALIO=()
		declare -a TLR=()
		declare -a TLW=()
		
		# Iterate through the output file and isolate Read IOPS, Write IOPS, Total IOPS, 99.99% Tail 
		#+ Latency for Reads and 99.99% Tail Latency for Writes
		for j in ${!SERIAL[@]}; do
			# Search by drive name (sda, sdb, sdc, etc...)

			RIOPS=$( grep "${DRVNAM[$j]}-" $READFIL | cut -f8 -d ';' | uniq )
			WIOPS=$( grep "${DRVNAM[$j]}-" $READFIL | cut -f49 -d ';' | uniq )	
			LATRD=$( grep "${DRVNAM[$j]}-" $READFIL | cut -f34 -d ';' | cut -f2 -d '=' )
			LATWR=$( grep "${DRVNAM[$j]}-" $READFIL | cut -f75 -d ';' | cut -f2 -d '=' )
			RDSIZ=${#LATRD}
			WRSIZ=${#LATWR}
			
			if [ $RIOPS -eq 0 ]; then
				TOTIOPS=$WIOPS
			elif [ $WIOPS -eq 0 ]; then
				TOTIOPS=$RIOPS
			else
				TOTIOPS=$( expr $RIOPS + $WIOPS )
			fi

			# Case statement used to prevent null exception via going out of bounds of the string
			case $RDSIZ in
				1)
					LATRD="0.00$LATRD"
					;;
				2)
					LATRD="0.0$LATRD"
					;;
				3)
					LATRD="0.$LATRD"
					;;
				*)
					LATRD="${LATRD:0:$RDSIZ-3}.${LATRD:$RDSIZ-3:$RDSIZ}"
					;;
			esac
	
			case $WRSIZ in
				1)
					LATWR="0.00$LATWR"
					;;
				2)
					LATWR="0.0$LATWR"
					;;
				3)
					LATWR="0.$LATWR"
					;;
				*)
					LATWR="${LATWR:0:$WRSIZ-3}.${LATWR:$WRSIZ-3:$WRSIZ}"
					;;
			esac
			
			# Append the data to the arrays
			READIO=(${READIO[@]} $RIOPS)
			WRITEIO=(${WRITEIO[@]} $WIOPS)
			TOTALIO=(${TOTALIO[@]} $TOTIOPS)
			TLR=(${TLR[@]} $LATRD)
			TLW=(${TLW[@]} $LATWR)
		done
	
		TYPE=$( grep "rw=" $i | cut -f2 -d '=' | uniq )
		# Write data to output file
		for k in ${!SERIAL[@]}; do
			# Drive Name
			printf '%s,' ${DRVNAM[$k]} >> $SUMMARY.csv
			# Drive Serial Number
			printf '%s,' ${SERIAL[$k]} >> $SUMMARY.csv
			# Type of test ran
			printf '%s,' $TYPE >> $SUMMARY.csv
			# IOPS for Read
			printf '%s,' ${READIO[$k]} >> $SUMMARY.csv
			# IOPS for Write
			printf '%s,' ${WRITEIO[$k]} >> $SUMMARY.csv
			# Total IOPS
			printf '%s,' ${TOTALIO[$k]} >> $SUMMARY.csv
			# Tail Latency for Read (in ms)
			printf '%s,' ${TLR[$k]} >> $SUMMARY.csv
			# Tail Latency for Write (in ms)
			printf '%s,' ${TLW[$k]} >> $SUMMARY.csv
			# New line
			echo >> $SUMMARY.csv	
		done
		
		# Make sure file can be accessed
		chmod 755 $SUMMARY.csv

	done
	mkdir $SUMMARY
	chmod 755 $SUMMARY

	mv *.log $SUMMARY
	mv *.fio_out $SUMMARY
}

parse_NCQ_data(){
	for i in $(ls *.csv); do
		NAME=""
		NAME=${i%.csv}
	
		# Name output summary file
		SUMMARY=""
		SUMMARY=""${MODEL[0]}"_"${FWREV[0]}"_"$NAME""
	
		# Initialize headers for summary file
		declare -a HEADERS=("Drive," "Read IOPS," "Write IOPS," "Total IOPS," "99.99% Tail Latency Read (ms)," 	"99.99% Tail Latency Write (ms),")
	
		# Initialize arrays for data
		declare -a DRVNAM=('sda' 'sdb' 'sdc' 'sdd' 'sde' 'sdf' 'sdg' 'sdh' 'sdi' 'sdj' 'sdk' 'sdl' 'sdm' 'sdn')	
		# Initialize output file
		> $SUMMARY.csv
		# Write headers to output file
		echo ${HEADERS[@]} >> $SUMMARY.csv
	
		declare -a READIO=()
		declare -a WRITEIO=()
		declare -a TOTALIO=()
		declare -a TLR=()
		declare -a TLW=()
			
		# Iterate through the output file and isolate Read IOPS, Write IOPS, Total IOPS, 99.99% Tail 
		#+ Latency for Reads and 99.99% Tail Latency for Writes
		for j in ${!DRVNAM[@]}; do
			# Search by drive name (sda, sdb, sdc, etc...)
	
			RIOPS=$( grep "${DRVNAM[$j]}-" $i | cut -f8 -d ';' | uniq )
			WIOPS=$( grep "${DRVNAM[$j]}-" $i | cut -f49 -d ';' | uniq )	
			LATRD=$( grep "${DRVNAM[$j]}-" $i | cut -f34 -d ';' | cut -f2 -d '=' )
			LATWR=$( grep "${DRVNAM[$j]}-" $i | cut -f75 -d ';' | cut -f2 -d '=' )
			RDSIZ=${#LATRD}
			WRSIZ=${#LATWR}
			
			if [ $RIOPS -eq 0 ]; then
				TOTIOPS=$WIOPS
			elif [ $WIOPS -eq 0 ]; then
				TOTIOPS=$RIOPS
			else
				TOTIOPS=$( expr $RIOPS + $WIOPS )
			fi
			# Case statement used to prevent null exception via going out of bounds of the string
			case $RDSIZ in
				1)
					LATRD="0.00$LATRD"
					;;
				2)
					LATRD="0.0$LATRD"
					;;
				3)
					LATRD="0.$LATRD"
					;;
				*)
					LATRD="${LATRD:0:$RDSIZ-3}.${LATRD:$RDSIZ-3:$RDSIZ}"
					;;
			esac

			case $WRSIZ in
				1)
					LATWR="0.00$LATWR"
					;;
				2)
					LATWR="0.0$LATWR"
					;;
				3)
					LATWR="0.$LATWR"
					;;
				*)
					LATWR="${LATWR:0:$WRSIZ-3}.${LATWR:$WRSIZ-3:$WRSIZ}"
					;;
			esac
		
			# Append the data to the arrays
			READIO=(${READIO[@]} $RIOPS)
			WRITEIO=(${WRITEIO[@]} $WIOPS)
			TOTALIO=(${TOTALIO[@]} $TOTIOPS)
			TLR=(${TLR[@]} $LATRD)
			TLW=(${TLW[@]} $LATWR)
		done

		# Write data to output file
		for k in ${!READIO[@]}; do
			# Drive Name
			printf '%s,' ${DRVNAM[$k]} >> $SUMMARY.csv
			# IOPS for Read
			printf '%s,' ${READIO[$k]} >> $SUMMARY.csv
			# IOPS for Write
			printf '%s,' ${WRITEIO[$k]} >> $SUMMARY.csv
			# Total IOPS
			printf '%s,' ${TOTALIO[$k]} >> $SUMMARY.csv
			# Tail Latency for Read (in ms)
			printf '%s,' ${TLR[$k]} >> $SUMMARY.csv
			# Tail Latency for Write (in ms)
			printf '%s,' ${TLW[$k]} >> $SUMMARY.csv
			# New line
			echo >> $SUMMARY.csv	
		done

		# Make sure file can be accessed
		chmod 755 $SUMMARY.csv
	done
	mkdir "Test_Files"
	mv -f "Synthetic-Fleet-DMA.csv" "Test_Files"
	mv -f "Synthetic-Fleet-NCQ.csv" "Test_Files"
	mv -f "64k-RandomRW-NCQ.csv" "Test_Files"
}


getData

# CD into random workloads directory
cd Random_Workloads

declare -a LETTERS=('a' 'b' 'c' 'd' 'e' 'f' 'g' 'h' 'i' 'j' 'k' 'l' 'm' 'n')
declare -a TESTSIZE=("_4k" "_64k" "_128k" "_256k" "_512k" "_1024k" "_2048k" )

if [ $( ls -f *.fio_conf 2>/dev/null | wc -l ) -eq 0 ]; then
	echo "No config files in current directory"
	exit
fi

# Loop through all .fio_conf files, add Serial Number after drives if not already there
#+ Also insert Model and FW Revision if not already there	
for i in $( ls -f *.fio_conf ); do
	
	# Insert serial number after drive names
	for j in ${!SERIAL[@]}; do
		DRV="sd${LETTERS[$j]}-"
		DRVSN="${SERIAL[$j]}-"

		if [ $( grep "$DRV$DRVSN" $i | wc -l ) -eq 0 ]; then
			sed -i -e "s/$DRV/$DRV$DRVSN/g" $i
		fi
	done

	# Rename config file to inclule Model Name and FW Revision
	NEWNAM="${MODEL[1]}_${FWREV[1]}_$i"
	if [[ $i != *"${MODEL[1]}_${FWREV[1]}"* ]]; then
		# Rename the file to include Model Name and FW Revision
		mv -T $i $NEWNAM
	fi
done



for i in ${TESTSIZE[@]}; do
	declare -a CONFFILS=()

	CONFFILS=($(find . -type f -name "*$i*".fio_conf 2> /dev/null | cut -f2 -d '/' 2> /dev/null))

	if [ ${#CONFFILS[@]} -eq 0 ]; then
		i=${i/_//}
		#echo "No fio config files for size $i"
	else
		runTest $i ${CONFFILS[@]}
	fi
done

cd ..
cd NCQ-Validation
./RunNCQTests.sh

echo "Analyzing results"
parse_NCQ_data
