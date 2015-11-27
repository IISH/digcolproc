#!/bin/bash
#
# merge_ead_item.sh



#-----------------------------------------------------------------------------------------------------------------------
# Preperations
#-----------------------------------------------------------------------------------------------------------------------
objnr=$1
id=$2

catalogUrl="$catalog/$archiveID/ArchiveContentList#$ID"
work=$work/$archiveID.$objnr
pid=$na/$archiveID.$ID
fileSet=$fileSet/$archiveID.$objnr
orgArchiveID=$archiveID
archiveID=$(basename "$fileSet")
log="${work}/${datestamp}T${time}.log"

if [ ! -d "$work" ] ; then
    mkdir -p $work
fi

echo "Starting merge for item $ID with objnr $objnr" >> $log
echo "Item $ID : catalogUrl: $catalogUrl" >> $log
echo "Item $ID : work : $work" >> $log
echo "Item $ID : pid : $pid" >> $log
echo "Item $ID : fileSet : $fileSet" >> $log
echo "Item $ID : archiveID : $archiveID" >> $log
echo "Item $ID : log : $log" >> $log



#-----------------------------------------------------------------------------------------------------------------------
# Is there a DROID file?
#-----------------------------------------------------------------------------------------------------------------------
profile_extended_csv=$fs_parent/.work/$orgArchiveID/ingest_ead/$archiveID/profile.droid.extended.csv
if [ ! -f "$profile_extended_csv" ] ; then
	exit_error "DROID analysis not found: $profile_extended_csv"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Is there a METS file?
#-----------------------------------------------------------------------------------------------------------------------
mets=$fs_parent/.work/$orgArchiveID/ingest_ead/$archiveID/mets.xml
if [ ! -f "$mets" ] ; then
	exit_error "No original METS document found: $mets"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Start the merge
#-----------------------------------------------------------------------------------------------------------------------
python ${DIGCOLPROC_HOME}/util/mets_to_droid.py --droid $profile_extended_csv --mets $mets >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "Failed to perform the merge!"
fi



#-----------------------------------------------------------------------------------------------------------------------
# End job
#-----------------------------------------------------------------------------------------------------------------------
echo "Merge finished for $pid" >> $log
exit 0