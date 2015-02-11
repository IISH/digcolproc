#!/bin/bash

# run.sh
#
# Usage:
# run.sh [na] [folder name]
#
# This script restores the files to their original state
# /a/b/c/10622/offloader/BULK12345

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"


# call_api_status
# Call the web service to PUT the status
function call_api_status() {
    pid=$1
    status=$2
    failure=$3

    # Update the status using the 'status' web service
    request_data="pid=$pid&status=$status&failure=$failure"
    echo "request_data=${request_data}">>$log
    curl --insecure --data "$request_data" "$ad/service/status"
    return $?
}



# Tell what we are doing
pid=$na/$archiveID
call_api_status $pid 0 false


# Lock the folder and it's contents
chown -R root:root $fileSet


# Download the files
ftp_script_base=$work/ftp.$archiveID.$datestamp
ftp_script=$ftp_script_base.files.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "mirror --verbose --delete /${archiveID} ${fileSet}" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    call_api_status $pid $statusUploadingToPermanentStorage true
    exit $rc
fi


# Release the folder and it's contents
chown -R $offloader:$offloader $fileSet


echo "Done. ALl went well at this side." >> $log
call_api_status $pid $statusMovedToPermanentStorage true



exit 0
