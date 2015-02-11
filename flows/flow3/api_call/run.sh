#!/bin/bash

# run.sh
#
# This calls several API methods in the following order:
# - backup:     Creates triggers for starting backups to the staging area
# - restore:    Creates triggers for starting a backup
# - ingest:     Creates triggers for starting the ingest procedure
# - folder:     Collects all folders from the acquisition database API that need to be created in the main local folder.
#               This is the only odd-one-out of the run.sh scripts. Here there are no folders that have a trigger file placed in them.
#               Rather is creates those folders for the offloader.

source "${DIGCOLPROC_HOME}config.sh"

log=/tmp/event.flow3.log


if [ ! -d $flow3_hotfolders ] ; then
    echo "No hotfolder found: ${flow3_hotfolders}">>$log
    exit 1
fi


# call_api_status
# Call the web service to set the status
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


# call_api_folders
# Call the 'folders' web service and extract the PIDs from the resulting JSON
# Create a folder for each PID we find.
function call_api_folders {

    for na in $flow3_hotfolders*
    do
        for offloader in $na/*
        do
            owner=$(basename $offloader)
            na=$(basename $na)
            echo "owner=${owner}:${na}">>$log


            request="curl --insecure '$ad/service/folders' | jq .pids[]"
            echo "request=${request}">>$log
            pids=$(eval ${request})

            # Create a folder for each PID
            for pid in ${pids}
            do
                # Remove the quotes around the PID
                pid="${pid%\"}"
                pid="${pid#\"}"
                id=$(basename $pid) # And remove the prefix

                echo "\$pid = $pid">>$log
                echo "\$id = $id">>$log

                # Create a folder for the PID
                folder=$offloader/$id
                # check if the directory exists
                if [ -d "$folder" ]; then
                    echo "The folder ${folder} already exists."
                    call_api_status $pid $statusFolderCreated true
                    continue
                fi

                    echo "mkdir -p $folder">>$log
                    mkdir -p "$folder"
                    chmod -R 775 "$folder"
                    chown -R $owner:$na "$folder"

                # check if the directory exists
                if [ -d "$folder" ];
                then
                    # directory exists
                    echo "Directory created: $folder">>$log

                    # Update the status using the 'status' web service
                    call_api_status $pid $statusFolderCreated false
                else
                    # directory doesn't exist
                    echo "Directory does not exists. Failed to create: $folder" >>$log

                    # Update the status using the 'status' web service
                    call_api_status $pid $statusFolderCreated true
                fi
            done
        done
    done

    return 0
}


# call_api_startBackup
# Call the startBackup web service and extract the PIDs from the resulting JSON
# Create a backup.txt event for each PID we find.
function call_api_startBackup() {

    request="curl --insecure '$ad/service/startBackup' | jq .pids[]"
    echo "request=${request}">>$log
    pids=$(eval ${request})

    for pid in ${pids}
    do
        # Remove the quotes around the PID
        pid="${pid%\"}"
        pid="${pid#\"}"
        id=$(basename $pid) # And remove the prefix
        "${DIGCOLPROC_HOME}util/place_event.sh" flow3 backup.txt
    done

    return 0
}


# call_api_restore
# Call the restore web service and extract the PIDs from the resulting JSON
# Create a backup.txt event for each PID we find.
function call_api_startRestore() {

    return 0 # Not implemented
}


# call_api_ingest
# Call the restore web service and extract the PIDs from the resulting JSON
# Create a backup.txt event for each PID we find.
function call_api_startIngest() {

    request="curl --insecure '$ad/service/startIngest' | jq .pids[]"
    echo "request=${request}">>$log
    pids=$(eval ${request})

    for pid in ${pids}
    do
        # Remove the quotes around the PID
        pid="${pid%\"}"
        pid="${pid#\"}"
        id=$(basename $pid) # And remove the prefix
        "${DIGCOLPROC_HOME}util/place_event.sh" flow3 ingest.txt
    done

    return 0
}


function call_api(){

    call_api_folders
    call_api_startBackup
    call_api_startRestore
    call_api_startIngest

    return 0
}

call_api

exit 0
