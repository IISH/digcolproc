#!/bin/bash

# run.sh
#
# Usage:
# run.sh [na] [folder name]
#
# This script ingests a fileSet
# /a/b/c/10622/offloader/BULK12345

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"


# call_api_status
# Call the web service to PUT the status
function call_api_status() {
    pid=$1
    status=$2
    failure=$3

    # Update the status using the 'status' web service
    method="${ad}/service/status"
    request_data="pid=$pid&status=$status&failure=$failure"
    echo "method=${method}">>$log
    echo "request_data=${request_data}">>$log
    curl --insecure --data "$request_data" "$method" >> $log
    if [[ $rc != 0 ]] ; then
        # api failure ?
        echo "The api gave an error response." >> $log
        #exit 1
    fi
    return 0
}


file_instruction=$fileSet/instruction.xml
if [ -f "$file_instruction" ] ; then
	echo "Instruction already present: $file_instruction">>$log
	echo "This may indicate the SIP is staged or the ingest is already in progress. This is not an error.">>$log
	exit 0
fi


# Tell what we are doing
pid=$na/$archiveID
call_api_status $pid $statusUploadingToPermanentStorage false


# Lock the folder and it's contents
chown -R root:root $fileSet


# Produce a droid analysis so we have our manifest
manifest=$fileSet/manifest.csv
rm $manifest
profile=$work/profile.droid
echo "Begin droid analysis for profile ${profile}" >> $log
droid --quiet -p $profile -a $fileSet -R >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    echo "Droid profiling threw an error." >> $log
    call_api_status $pid $statusBackupRunning true
    exit $rc
fi


# produce a report.
profile_csv=$profile.csv
droid --quiet -p $profile -e $profile_csv
if [[ $rc != 0 ]] ; then
    echo "Droid reporting threw an error." >> $log
    call_api_status $pid $statusBackupRunning true
    exit $rc
fi
if [ ! -f $profile_csv ] ; then
    echo "Unable to create a droid profile: ${profile_csv}" >> $log
    call_api_status $pid $statusBackupRunning true
    exit $rc
fi


# Now extend the report with two columns: a md5 checksum and a persistent identifier
python droid_extend_csv.py --sourcefile $profile_csv --targetfile $manifest --na $na --fileset $fileSet >> $log
if [[ $rc != 0 ]] ; then
    echo "Failed to extend the droid report to the manifest.">>$log
    exit 1
fi


# The droid analysis does not include itself, so we add it to the manifest
md5_hash=$(md5sum $manifest | cut -d ' ' -f 1)
echo ""","1","file:/${archivalID}/","/${archivalID}/manifest.csv","manifest.csv","METHOD","STATUS","SIZE","File","csv","","EXTENSION_MISMATCH","${md5_hash}","FORMAT_COUNT","PUID","text/csv","Comma Separated Values","FORMAT_VERSION", "${pid}"">>$manifest


# Now start the reverse mirror
# Upload the files
ftp_script_base=$work/ftp.$archiveID.$datestamp
ftp_script=$ftp_script_base.files.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "mirror --reverse --delete --verbose ${fileSet} /${archiveID}" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    call_api_status $pid $statusBackupRunning true
    exit $rc
fi


# Produce instruction from the report.
instruction=$fileSet/instruction.xml
python droid_to_instruction.py --sourcefile $manifest --targetfile $instruction --objid "$pid" --access $flow_access --submission_date=$(date) ---autoIngestValidInstruction "$flow_autoIngestValidInstruction" --label "$archiveID $flow_client" --action add --notificationEMail "$flow_notificationEMail" >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    echo "Failed to produce an instruction." >> $log
    call_api_status $pid $statusUploadingToPermanentStorage true
    exit $rc
fi
if [ ! -f $instruction ] ; then
    call_api_status $pid $statusUploadingToPermanentStorage true
    echo "Failed to create an instruction."
    exit 1
fi


# Upload the instruction
ftp_script=$ftp_script_base.instruction.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "put -O /${archiveID} ${instruction}" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    call_api_status $pid $statusUploadingToPermanentStorage true
    exit $rc
fi


echo "Done. ALl went well at this side." >> $log
call_api_status $pid $statusMovedToPermanentStorage true



exit 0
