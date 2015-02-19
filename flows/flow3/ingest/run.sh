#!/bin/bash

# run.sh
#
# Usage:
# run.sh [na] [folder name]
#
# This script ingests a fileSet
# /a/b/c/10622/offloader/BULK12345

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh


# Tell what we are doing
pid=$na/$archiveID
call_api_status $pid $UPLOADING_TO_PERMANENT_STORAGE


file_instruction=$fileSet/instruction.xml
if [ -f "$file_instruction" ] ; then
	msg="Instruction already present: ${file_instruction}. This may indicate the SIP is staged or the ingest is already in progress."
	call_api_status $pid $UPLOADING_TO_PERMANENT_STORAGE true "$msg"
	exit 1
fi


# Lock the folder and it's contents
chown -R root:root $fileSet


# Produce a droid analysis so we have our manifest
profile=$work/profile.droid
profile_csv=$profile.csv
profile_extended_csv=$profile.extended.csv
echo "Begin droid analysis for profile ${profile}" >> $log
droid --quiet -p $profile -a $fileSet -R >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    msg="Droid profiling threw an error."
    call_api_status $pid $UPLOADING_TO_PERMANENT_STORAGE true "$msg"
    exit $rc
fi


# produce a report.
droid --quiet -p $profile -e $profile_csv
if [[ $rc != 0 ]] ; then
    msg="Droid reporting threw an error."
    call_api_status $pid $UPLOADING_TO_PERMANENT_STORAGE true "$msg"
    exit $rc
fi
if [ ! -f $profile_csv ] ; then
    msn="Unable to create a droid profile: ${profile_csv}"
    call_api_status $pid $UPLOADING_TO_PERMANENT_STORAGE true "$msg"
    exit $rc
fi


# Now extend the report with two columns: a md5 checksum and a persistent identifier
python droid_extend_csv.py --sourcefile $profile_csv --targetfile $profile_extended_csv --na $na --fileset $fileSet >> $log
if [[ $rc != 0 ]] ; then
    msg="Failed to extend the droid report with a PID and md5 checksum."
    call_api_status $pid $UPLOADING_TO_PERMANENT_STORAGE true "$msg"
    exit 1
fi


# Create a mets document
manifest=$fileSet/manifest.xml
python droid_to_mets.py --sourcefile $profile_extended_csv --targetfile $manifest --objid "$pid"
rc=$?
if [[ $rc != 0 ]] ; then
    msg="Failed to create a mets document."
    call_api_status $pid $UPLOADING_TO_PERMANENT_STORAGE true "$msg"
    exit $rc
fi
if [ ! -f $manifest ] ; then
    msg="Failed to find a mets file at ${manifest}"
    call_api_status $pid $UPLOADING_TO_PERMANENT_STORAGE true "$msg"
    exit 1
fi


# ToDo: Add the mets file to the record itself with as PID the $pid.


# Now start the reverse mirror
# Upload the files
ftp_script_base=$work/ftp.$archiveID.$datestamp
ftp_script=$ftp_script_base.files.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "mirror --reverse --delete --verbose ${fileSet} /${archiveID}" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    msg="FTP error with uploading the files."
    call_api_status $pid $UPLOADING_TO_PERMANENT_STORAGE true "$msg"
    exit $rc
fi


# Produce instruction from the report.
python droid_to_instruction.py -s $profile_extended_csv -t $file_instruction --objid "$pid" --access "$flow_access" --submission_date "$datestamp" --autoIngestValidInstruction "$flow_autoIngestValidInstruction" --label "$archiveID $flow_client" --action "add" --notificationEMail "$flow_notificationEMail" --plan "StagingfileBindPIDs,StagingfileIngestMaster" >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    rm $file_instruction
    msg="Failed to create an instruction."
    call_api_status $pid $UPLOADING_TO_PERMANENT_STORAGE true "$msg"
    exit $rc
fi
if [ ! -f $file_instruction ] ; then
    msg="Failed to find an instruction at ${file_instruction}"
    call_api_status $pid $UPLOADING_TO_PERMANENT_STORAGE true "$msg"
    exit 1
fi


# Upload the instruction
ftp_script=$ftp_script_base.instruction.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "put -O /${archiveID} ${file_instruction}" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    msg="FTP error with uploading the object repository instruction."
    call_api_status $pid $UPLOADING_TO_PERMANENT_STORAGE true "$msg"
    exit $rc
fi


echo "Done. ALl went well at this side." >> $log
call_api_status $pid $MOVED_TO_PERMANENT_STORAGE


exit 0
