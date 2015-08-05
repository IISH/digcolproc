#!/bin/bash
#
# run.sh
#
# Usage:
# run.sh [na] [folder name]
#

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh



#-----------------------------------------------------------------------------------------------------------------------
# Is there an access file ?
#-----------------------------------------------------------------------------------------------------------------------
access_file=$fileSet/.access.txt
if [ ! -f "$access_file" ] ; then
	exit_error "Access file not found: $access_file"
fi
access=$(<"$access_file")



#-----------------------------------------------------------------------------------------------------------------------
# Start ingest for each item
#-----------------------------------------------------------------------------------------------------------------------
curFileSet=$fileSet
curArchiveID=$archiveID
curWork=$work
while read line
do
    IFS=, read objnr ID <<< "$line"

    fileSet=$curFileSet/$curArchiveID.$objnr
    archiveID=$(basename "$fileSet")
    catalogUrl="$catalog/$curArchiveID/ArchiveContentList#$ID"
    work=$curWork/$curArchiveID.$objnr
    pid=$na/$curArchiveID.$ID
    profile_extended_csv=$fs_parent/.work/$curArchiveID/ingest_ead/$archiveID/profile.droid.extended.csv

    echo "fileSet: $fileSet" >> $log
    echo "archiveID: $archiveID" >> $log
    echo "catalogUrl: $catalogUrl" >> $log
    echo "work: $work" >> $log
    echo "pid: $pid" >> $log

    if [ ! -d "$work" ] ; then
        mkdir $work
    fi

    file_instruction=$fileSet/instruction.xml
    if [ ! -f "$file_instruction" ] ; then
        exit_error "Instruction not found: $file_instruction"
    fi

    source ../mets.sh
done < <(python ${DIGCOLPROC_HOME}/util/concordance_to_list.py --concordance "$fs_parent/.work/$archiveID/validate/concordanceValid.csv")
fileSet=$curFileSet
archiveID=$curArchiveID
work=$curWork



#-----------------------------------------------------------------------------------------------------------------------
# End job
#-----------------------------------------------------------------------------------------------------------------------
echo "Done. All went well at this side." >> $log
exit 0