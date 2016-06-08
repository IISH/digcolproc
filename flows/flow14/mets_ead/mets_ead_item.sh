#!/bin/bash
#
# ingest_ead_item.sh



#-----------------------------------------------------------------------------------------------------------------------
# Preperations
#-----------------------------------------------------------------------------------------------------------------------
objnr=$1
ID=$2

catalogUrl="$catalog/$archiveID/ArchiveContentList#$ID"
work=$work/$archiveID.$objnr
pid=$na/$archiveID.$ID
fileSet=$fileSet/$archiveID.$objnr
orgArchiveID=$archiveID
archiveID=$(basename "$fileSet")
log="${work}/${datestamp}T${time}.log"
profile_extended_csv=$fs_parent/.work/$orgArchiveID/ingest_ead/$archiveID/profile.droid.extended.csv

if [ ! -d "$work" ] ; then
    mkdir -p $work
fi

echo "Starting METS creation for item $ID with objnr $objnr" >> $log
echo "Item $ID : catalogUrl: $catalogUrl" >> $log
echo "Item $ID : work : $work" >> $log
echo "Item $ID : pid : $pid" >> $log
echo "Item $ID : fileSet : $fileSet" >> $log
echo "Item $ID : archiveID : $archiveID" >> $log
echo "Item $ID : log : $log" >> $log
echo "Item $ID : profile_extended_csv : $profile_extended_csv" >> $log



#-----------------------------------------------------------------------------------------------------------------------
# Is there an instruction ?
#-----------------------------------------------------------------------------------------------------------------------
file_instruction=$fileSet/instruction.xml
if [ ! -f "$file_instruction" ] ; then
	exit_error "Instruction not found: $file_instruction"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Start the METS creation
#-----------------------------------------------------------------------------------------------------------------------
source ../mets.sh



#-----------------------------------------------------------------------------------------------------------------------
# End job
#-----------------------------------------------------------------------------------------------------------------------
echo "METS creation finished for $pid" >> $log
exit 0