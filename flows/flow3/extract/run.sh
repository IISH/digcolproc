#!/bin/bash

# run.sh
#
# Usage:
# run.sh [na] [folder name]
#
# This script retrieves a package from the object repository and unpacks it.
# It expects a manifest to be present to validate each folder and file.



#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh
pid=$na/$archiveID
TASK_ID=$EXTRACT


#-----------------------------------------------------------------------------------------------------------------------
# Commence job. Tell what we are doing
#-----------------------------------------------------------------------------------------------------------------------
call_api_status $pid $TASK_ID $RUNNING



#-----------------------------------------------------------------------------------------------------------------------
# Extract
#-----------------------------------------------------------------------------------------------------------------------
source ./extract.sh



call_api_status $pid $TASK_ID $FINISHED
echo "I think we are done for today." >> $log
exit 0