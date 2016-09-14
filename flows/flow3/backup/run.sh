#!/bin/bash

# run.sh
#
# Backup the folder with ftp
# Then create a droid analysis
#
# The content is handles in one of two ways:
# 1. Bulk files and folders
# Here all files and folders are backup as is.
#
# 2. Package
# If the offload content comes in the form of a single file named as [archiveId].[zip|tar|tar.gz|rar]
# then the package is first backupped and then unpacked.


#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh
pid=$na/$archiveID
TASK_ID=$BACKUP



#-----------------------------------------------------------------------------------------------------------------------
# Commence job. Tell what we are doing
#-----------------------------------------------------------------------------------------------------------------------
call_api_status $pid $TASK_ID $RUNNING



#-----------------------------------------------------------------------------------------------------------------------
# Lock the folder and it's contents
#-----------------------------------------------------------------------------------------------------------------------
chown -R root:root $fileSet



#-----------------------------------------------------------------------------------------------------------------------
# Upload the files.
#-----------------------------------------------------------------------------------------------------------------------
ftp_script_base=$work/ftp.$archiveID.$datestamp
ftp_script=$ftp_script_base.files.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "mirror --reverse --delete --verbose --exclude-glob *.md5 ${fileSet} /${archiveID}" "$flow_ftp_connection" "$log"
if [[ $? != 0 ]] ; then
    exit_error "$pid" $TASK_ID "FTP error"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Is this a package?
#-----------------------------------------------------------------------------------------------------------------------
source ../package.sh
unpack


#-----------------------------------------------------------------------------------------------------------------------
# Produce a droid analysis
#-----------------------------------------------------------------------------------------------------------------------
profile=$work/profile.droid
echo "Begin droid analysis for profile ${profile}" >> $log
droid --recurse -p $profile --profile-resources $fileSet>>$log
if [[ $? != 0 ]] ; then
    exit_error "$pid" $TASK_ID "Droid profiling threw an error."
fi
if [[ ! -f $profile ]] ; then
    exit_error "$pid" $TASK_ID "Unable to find a DROID profile."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Produce a droid report so we have our manifest
#-----------------------------------------------------------------------------------------------------------------------
profile_csv=$fileSet/manifest.csv
droid -p $profile --export-file $profile_csv >> $log
if [[ $? != 0 ]] ; then
    exit_error "$pid" $TASK_ID "Droid reporting threw an error."
fi
if [[ ! -f $profile_csv ]] ; then
    exit_error "$pid" $TASK_ID "Unable to find a DROID report."
fi
chmod 444 $profile_csv



#-----------------------------------------------------------------------------------------------------------------------
# POST our manifest.csv
#-----------------------------------------------------------------------------------------------------------------------
call_api_manifest "$pid" "$archiveID" "$profile_csv"
if [[ $? != 0 ]] ; then
    exit_error "$pid" $TASK_ID "Droid reporting threw an error."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Release the folder and it's contents
#-----------------------------------------------------------------------------------------------------------------------
chown -R $offloader:$na $fileSet



#-----------------------------------------------------------------------------------------------------------------------
# End job
#-----------------------------------------------------------------------------------------------------------------------
call_api_status $pid $TASK_ID $FINISHED
exit 0
