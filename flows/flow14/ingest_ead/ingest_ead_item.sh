#!/bin/bash
#
# ingest_ead_item.sh



#-----------------------------------------------------------------------------------------------------------------------
# Preperations
#-----------------------------------------------------------------------------------------------------------------------
objnr=$1
id=$2

refSeqNr=2
catalogUrl="$catalog/$archiveID/ArchiveContentList#$ID"
work=$work/$archiveID.$objnr
pid=$na/$archiveID.$ID
fileSet=$fileSet/$archiveID.$objnr
archiveID=$(basename "$fileSet")
log="${work}/${datestamp}T${time}.log"

if [ ! -d "$work" ] ; then
    mkdir -p $work
fi

echo "Starting an ingest for item $ID with objnr $objnr" >> $log
echo "Item $ID : catalogUrl: $catalogUrl" >> $log
echo "Item $ID : work : $work" >> $log
echo "Item $ID : pid : $pid" >> $log
echo "Item $ID : fileSet : $fileSet" >> $log
echo "Item $ID : archiveID : $archiveID" >> $log
echo "Item $ID : log : $log" >> $log



#-----------------------------------------------------------------------------------------------------------------------
# Start the ingest followed by METS creation
#-----------------------------------------------------------------------------------------------------------------------
source ../ingest.sh
# TODO: source ../mets.sh



#-----------------------------------------------------------------------------------------------------------------------
# End job
#-----------------------------------------------------------------------------------------------------------------------
exit 0