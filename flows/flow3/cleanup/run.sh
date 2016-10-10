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
fileSet="${work}/cleanup"
if [ -d "$fileSet" ]
then
    rm -rf "$fileSet"
fi
mkdir "$fileSet"



#-----------------------------------------------------------------------------------------------------------------------
# Extract
#-----------------------------------------------------------------------------------------------------------------------
source ../extract/extract.sh
rc=$?
rm -rf "$fileSet"

if [[ $rc != 0 ]] # This should never happen as the extract procedure exits when an error occurs.
then
    exit_error "$pid" $TASK_ID "Error ${rc}: unable to cleanup ${fileSet}. The extraction reported problems."
fi

