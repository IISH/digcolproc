#!/bin/bash

# run.sh
#
# Collects all folders from the acquisition database API that need to be created in the main local folder.
#

source "${DIGCOLPROC_HOME}config.sh"

log=/tmp/event.flow3.log

# We only accept folders

# No folder created yet
statusNewDigitalMaterialCollection=1

# A folder has been created
statusFolderCreated=2

# Digital material has been uploaded
statusMaterialUploaded=3

# A backup of the digital material is being made
statusBackupRunning=4

# A backup of the digital material has been created
statusBackupFinished=5

# Digital material is ready for permanent storage
statusReadyForPermanentStorage=6

# Digital material is being uploaded to permanent storage
statusUploadingToPermanentStorage=7

# Digital material has been moved to permanent storage
statusMovedToPermanentStorage=8


if [ ! -d $flow3_hotfolders ] ; then
    echo "No hotfolder found: ${flow3_hotfolders}">>$log
    exit 1
fi

for na in $flow3_hotfolders*
do
    for offloader in $na/*
    do
        owner=$(basename $offloader)
        na=$(basename $na)
        echo "owner=${owner}:${na}">>$log

        # Call the 'folders' web service and extract the PIDs from the resulting JSON
        request="curl --insecure '$ad/service/folders' | jq .pids[]"
        echo "request=${request}"
        pids=$(eval ${request})

        # Create a folder for each PID
        for pid in ${pids}
        do
            # Remove the quotes around the PID
            pid="${pid%\"}"
            pid="${pid#\"}"
            pid=$(basename $pid) # And remove the prefix

            echo "\$pid = $pid">>$log
            if [ -z "$pid" ] ; then
                echo "Empty value for pid"  >>$log
                exit -1
            fi

            # Create a folder for the PID
            folder=$offloader/$pid
            echo "mkdir -p $folder">>$log
            mkdir -p "$folder"
            chmod -R 775 "$folder"
            chown -R $owner:$na "$folder"

            # check if the directory already exists
            if [ -d "$folder" ];
            then
                # directory exists
                echo "Directory created: $folder">>$log

                # Update the status using the 'status' web service
                request_data="pid=$pid&status=$statusFolderCreated&failure=false"
                echo "request_data=${request_data}">>$log
                curl --insecure --data "$request_data" "$ad/service/status"
            else
                # directory doesn't exist
                echo "Directory does not exists. Failed to create: $folder" >>$log

                # Update the status using the 'status' web service
                request_data="pid=$pid&status=$statusFolderCreated&failure=true"
                echo "request_data=${request_data}">>$log
                curl --insecure --data "$request_data" "$ad/service/status"
            fi
        done
    done
    break # we only handle one offloader folder.
done


exit 0
