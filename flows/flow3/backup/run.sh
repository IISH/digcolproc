#!/bin/bash

# run.sh
#
# Backup the folder with ftp
# Then create a droid analysis
#

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh


# Tell what we are doing
pid=$na/$archiveID
call_api_status $pid $BACKUP_RUNNING


# Lock the folder and it's contents
chown -R root:root $fileSet


# Produce a droid analysis so we have our manifest
profile=$work/profile.droid
echo "Begin droid analysis for profile ${profile}" >> $log
droid --quiet -p $profile -a $fileSet -R
rc=$?
if [[ $rc != 0 ]] ; then
    msg="Droid profiling threw an error."
    call_api_status $pid $BACKUP_RUNNING true "$msg"
    exit $rc
fi


# produce a report
droid_report=$fileSet/manifest.csv
droid --quiet -p $profile -e $droid_report  >> $log
if [[ $rc != 0 ]] ; then
    msg="Droid reporting threw an error."
    call_api_status $pid $BACKUP_RUNNING true "$msg"
    exit $rc
fi


# Now start the reverse mirror
# Upload the files
ftp_script_base=$work/ftp.$archiveID.$datestamp
ftp_script=$ftp_script_base.files.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "mirror --reverse --delete --verbose ${fileSet} /${archiveID}" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    msg="FTP error."
    call_api_status $pid $BACKUP_RUNNING true "$msg"
    exit $rc
fi


# Release the folder and it's contents
chown -R $offloader:$offloader $fileSet

# Update the status
call_api_status $pid $BACKUP_FINISHED

exit 0
