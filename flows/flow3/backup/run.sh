#!/bin/bash

# run.sh
#
# Backup the folder with ftp
# Then create a droid analysis
#

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


# Tell what we are doing
pid=$na/$archiveID
call_api_status $pid $statusBackupRunning false


# Lock the folder and it's contents
chown -R root:root $fileSet


# Produce a droid analysis so we have our manifest
profile=$work/profile.droid
echo "Begin droid analysis for profile ${profile}" >> $log
droid --quiet -p $profile -a $fileSet -R
rc=$?
if [[ $rc != 0 ]] ; then
    echo "Droid profiling threw an error." >> $log
    call_api_status $pid $statusBackupRunning true
    exit $rc
fi


# produce a report
droid_report=$fileSet/manifest.csv
droid --quiet -p $profile -e $droid_report  >> $log
if [[ $rc != 0 ]] ; then
    echo "Droid reporting threw an error." >> $log
    call_api_status $pid $statusBackupRunning true
    exit $rc
fi


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


# Release the folder and it's contents
chown -R $offloader:$offloader $fileSet

# Update the status
call_api_status $pid $statusBackupFinished false

exit 0
