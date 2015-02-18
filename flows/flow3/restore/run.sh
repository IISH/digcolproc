#!/bin/bash

# run.sh
#
# Usage:
# run.sh [na] [folder name]
#
# This script restores the files to their original state
# /a/b/c/10622/offloader/BULK12345

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh


# Tell what we are doing
pid=$na/$archiveID
call_api_status $pid $UPLOADING_TO_PERMANENT_STORAGE


# Lock the folder and it's contents
chown -R root:root $fileSet


# Download the files
ftp_script_base=$work/ftp.$archiveID.$datestamp
ftp_script=$ftp_script_base.files.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "mirror --verbose --delete /${archiveID} ${fileSet}" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    msg="FTP error."
    call_api_status $pid $RESTORE_RUNNING true "$msg"
    exit $rc
fi


# Release the folder and it's contents
chown -R $offloader:$offloader $fileSet


echo "Done. ALl went well at this side." >> $log
call_api_status $pid $RESTORE_FINISHED



exit 0
