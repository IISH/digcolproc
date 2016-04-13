#!/bin/bash

# run.sh
#
# Usage:
# run.sh [na] [folder name]
#
# This script restores the files to their original state
# /a/b/c/10622/offloader/BULK12345



#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh
STATUS=$UPLOADING_TO_PERMANENT_STORAGE
pid=$na/$archiveID



#-----------------------------------------------------------------------------------------------------------------------
# Commence job. Tell what we are doing
#-----------------------------------------------------------------------------------------------------------------------
call_api_status $pid $STATUS



#-----------------------------------------------------------------------------------------------------------------------
# Lock the folder and it's contents
#-----------------------------------------------------------------------------------------------------------------------
chown -R root:root $fileSet



#-----------------------------------------------------------------------------------------------------------------------
# Mirror the files from the backup onto the sorting area
#-----------------------------------------------------------------------------------------------------------------------
ftp_script_base=$work/ftp.$archiveID.$datestamp
ftp_script=$ftp_script_base.files.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "mirror --verbose --exclude-glob *.md5 --delete /${archiveID} ${fileSet}" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "$pid" ${STATUS} "FTP error."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Release the folder and it's contents
#-----------------------------------------------------------------------------------------------------------------------
chown -R $offloader:$na $fileSet



#-----------------------------------------------------------------------------------------------------------------------
# End job
#-----------------------------------------------------------------------------------------------------------------------
echo "Done. ALl went well at this side." >> $log
call_api_status $pid ${RESTORE_FINISHED}
exit 0
