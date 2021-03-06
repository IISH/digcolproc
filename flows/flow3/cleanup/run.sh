#!/bin/bash

# run.sh
#
# Usage:
# run.sh [na] [folder name]
#
# This uses the extract/run/sh script to determine the package is valid.



#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh
pid=$na/$archiveID
TASK_ID=$CLEANUP



#-----------------------------------------------------------------------------------------------------------------------
# Commence job. Tell what we are doing
#-----------------------------------------------------------------------------------------------------------------------
call_api_status $pid $TASK_ID $RUNNING



#-----------------------------------------------------------------------------------------------------------------------
# Create a dummy fileset
#-----------------------------------------------------------------------------------------------------------------------
empty_folder="/tmp/empty"
mkdir -p "$empty_folder"

original_fileSet="$fileSet"
fileSet="${work}/package/${archiveID}"
fs_parent="${work}/package"
mkdir -p "$fileSet"
rsync -r --delete "$empty_folder/" "$fileSet"



#-----------------------------------------------------------------------------------------------------------------------
# Extract
#-----------------------------------------------------------------------------------------------------------------------
cd ../extract
source extract.sh
rc=$?
rsync -r --delete "$empty_folder/" "$fileSet"

if [[ $rc != 0 ]] # This should never happen as the extract procedure exits when an error occurs.
then
    exit_error "$pid" $TASK_ID "Error ${rc}: unable to cleanup ${fileSet}. The extraction reported problems."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Remove the fileSet
#-----------------------------------------------------------------------------------------------------------------------
cd ../cleanup
fileSet="$original_fileSet"
fs_parent=$(dirname $fileSet)
echo "Removing ${fileSet}"
message="${work}/message.txt"
echo "Cleanup OK for ${fileSet}">"$message"
/usr/bin/sendmail --body "$message" --from "$flow_client" --to "$flow_notificationEMail" --subject "Completed ${archiveID}" --mail_relay "$mail_relay" --mail_user "$mail_user" --mail_password "$mail_password"
rsync -r --delete "$empty_folder/" "$fileSet"
rm -rf "$fileSet"




#-----------------------------------------------------------------------------------------------------------------------
# Done
#-----------------------------------------------------------------------------------------------------------------------
call_api_status $pid $TASK_ID $FINISHED


echo "I think we are done for today." >> "$log"
exit 0

