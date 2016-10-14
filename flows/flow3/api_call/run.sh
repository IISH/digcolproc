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



#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
mkdir -p "/tmp/dummy" # All log goes into this directory
source "${DIGCOLPROC_HOME}setup.sh" "${DIGCOLPROC_HOME}/flows/flow3/api_call/run.sh" api_call "/tmp/dummy"
source ../call_api_status.sh



#-----------------------------------------------------------------------------------------------------------------------
# Make sure we have a hotfolder directory
#-----------------------------------------------------------------------------------------------------------------------
if [ ! -d $flow3_hotfolders ] ; then
    echo "No hotfolder found: ${flow3_hotfolders}">>$log
    exit 1
fi



#-----------------------------------------------------------------------------------------------------------------------
# call_api_folders
# Call the 'folders' web service and extract the PIDs from the resulting JSON
# Create a folder for each PID we find.
#-----------------------------------------------------------------------------------------------------------------------
function call_api_folders {
    echo -e "\n\nfunction: call_api_folders" | tee -a $log # debug info

    for na in $flow3_hotfolders*
    do
        for offloader in $na/*
        do
            owner=$(basename $offloader)
            na=$(basename $na)
            echo "owner=${owner}:${na}">>$log

            # get all pids with a status NEW_DIGITAL_MATERIAL_COLLECTION
            request="curl --insecure ${acquisition_database}/service/folders?access_token=${acquisition_database_access_token} | jq .pids[]"
            echo "request: ${request}" | tee -a $log # debug info

            pids=$(eval ${request})
            echo "Returned pids: ${pids}" | tee -a $log # debug info

            # Create a folder for each PID
            for pid in ${pids}
            do
                # Remove the quotes around the PID. E.g. "10622/BULK12345" becomes 10622/BULK12345
                pid="${pid%\"}"
                pid="${pid#\"}"
                id=$(basename $pid) # And remove the prefix so we get BULK12345

                echo "\$pid = $pid" | tee -a $log # debug info
                echo "\$id = $id" | tee -a $log # debug info

                # Tell what we are doing
                call_api_status $pid $FOLDER $RUNNING

                # Create a folder for the PID
                folder=$offloader/$id

                # check if the directory exists
                if [ -d "$folder" ]; then
                    # TODO: Question: is it necessary to send a failure and the message 'folder already exists'? You cannot go to the next status!
                    # TODO: Question: shouldn't we also do the chmod and chown commands, to be sure the rights are set okay?
                    #msg="The folder ${folder} already exists."
                    #call_api_status $pid $FOLDER_CREATED true "$msg"
                    call_api_status $pid $FOLDER $FINISHED

					# set permissions
	                chmod -R 775 "$folder"
	                chown -R $owner:$na "$folder"

	                # loop to next pid
                    continue
                fi

                mkdir -p "$folder"
                chmod -R 775 "$folder"
                chown -R $owner:$na "$folder"

                # check if the directory exists
                if [ -d "$folder" ];
                then
                    # directory exists
                    echo "Directory created: $folder">>$log

                    # Update the status using the 'status' web service
                    call_api_status $pid $FOLDER $FINISHED
                else
                    # directory doesn't exist
                    msg="Directory does not exists. Failed to create: $folder"

                    # Update the status using the 'status' web service
                    call_api_status $pid $FOLDER $FAILED $msg
                fi
            done
        done
    done

    return 0
}



#-----------------------------------------------------------------------------------------------------------------------
# call_api_startBackup
# Call the startBackup web service and extract the PIDs from the resulting JSON
# Create a backup.txt event for each PID we find.
#-----------------------------------------------------------------------------------------------------------------------
function call_api_backup() {
    echo -e "\n\nfunction: call_api_backup" | tee -a $log # debug info

    # Get all the PIDs with a status MATERIAL_UPLOADED
    request="curl --insecure ${acquisition_database}/service/startBackup?access_token=${acquisition_database_access_token} | jq .pids[]"
    echo "request: ${request}" | tee -a $log # debug info

    pids=$(eval ${request})
    echo "Returned pids: ${pids}" | tee -a $log # debug info

    for pid in ${pids}
    do
        # Remove the quotes around the PID
        pid="${pid%\"}"
        pid="${pid#\"}"
        id=$(basename $pid) # And remove the prefix

        echo "\$pid = $pid" | tee -a $log # debug info
        echo "\$id = $id" | tee -a $log # debug info

        if [[ $? == 0 ]] ; then
            echo "${DIGCOLPROC_HOME}util/place_event.sh flow3 backup.txt ${id}" | tee -a $log # debug info
            "${DIGCOLPROC_HOME}util/place_event.sh" flow3 backup.txt $id
        fi
    done

    return 0
}



#-----------------------------------------------------------------------------------------------------------------------
# call_api_restore
# Call the web service and extract the PIDs from the resulting JSON
# Create a backup.txt event for each PID we find.
#-----------------------------------------------------------------------------------------------------------------------
function call_api_restore() {
    echo -e "\n\nfunction: call_api_restore" | tee -a $log # debug info

    # Get all the PIDs with a status READY_FOR_RESTORE
    request="curl --insecure ${acquisition_database}/service/startRestore?access_token=${acquisition_database_access_token} | jq .pids[]"
    echo "request: ${request}" | tee -a $log # debug info

    pids=$(eval ${request})
    echo "Returned pids: ${pids}" | tee -a $log # debug info

    for pid in ${pids}
    do
        # Remove the quotes around the PID
        pid="${pid%\"}"
        pid="${pid#\"}"
        id=$(basename $pid) # And remove the prefix

        echo "\$pid = $pid" | tee -a $log # debug info
        echo "\$id = $id" | tee -a $log # debug info

        if [[ $? == 0 ]] ; then
            echo "${DIGCOLPROC_HOME}util/place_event.sh flow3 restore.txt ${id}" | tee -a $log # debug info
            "${DIGCOLPROC_HOME}util/place_event.sh" flow3 restore.txt $id
        fi
    done

    return 0
}



#-----------------------------------------------------------------------------------------------------------------------
# call_api_ingest
# Call the web service and extract the PIDs from the resulting JSON
# Create a backup.txt event for each PID we find.
#-----------------------------------------------------------------------------------------------------------------------
function call_api_ingest() {
    echo -e "\n\nfunction: call_api_ingest" | tee -a $log # debug info

    # Get all the PIDs with a status READY_FOR_PERMANENT_STORAGE
    request="curl --insecure $acquisition_database/service/startIngest?access_token=${acquisition_database_access_token} | jq .pids[]"
    echo "request: ${request}" | tee -a $log # debug info

    pids=$(eval ${request})
    echo "Returned pids: ${pids}" | tee -a $log # debug info

    for pid in ${pids}
    do
        # Remove the quotes around the PID
        pid="${pid%\"}"
        pid="${pid#\"}"
        id=$(basename $pid) # And remove the prefix

        echo "\$pid = $pid" | tee -a $log # debug info
        echo "\$id = $id" | tee -a $log # debug info

        if [[ $? == 0 ]] ; then
            echo "${DIGCOLPROC_HOME}util/place_event.sh flow3 ingest.txt ${id}" | tee -a $log # debug info
            "${DIGCOLPROC_HOME}util/place_event.sh" flow3 ingest.txt $id
        fi
    done

    return 0
}



#-----------------------------------------------------------------------------------------------------------------------
# call_api_cleanup
# Call the web service and kickstart a removal procedure
# Create a cleanup.txt event for each PID we find.
#-----------------------------------------------------------------------------------------------------------------------
function call_api_cleanup() {
    echo -e "\n\nfunction: call_api_ingest" | tee -a $log # debug info

    # Get all the PIDs with a status READY_FOR_PERMANENT_STORAGE
    request="curl --insecure $acquisition_database/service/startCleanup?access_token=${acquisition_database_access_token} | jq .pids[]"
    echo "request: ${request}" | tee -a $log # debug info

    pids=$(eval ${request})
    echo "Returned pids: ${pids}" | tee -a $log # debug info

    for pid in ${pids}
    do
        # Remove the quotes around the PID
        pid="${pid%\"}"
        pid="${pid#\"}"
        id=$(basename $pid) # And remove the prefix

        echo "\$pid = $pid" | tee -a $log # debug info
        echo "\$id = $id" | tee -a $log # debug info

        if [[ $? == 0 ]] ; then
            echo "${DIGCOLPROC_HOME}util/place_event.sh flow3 cleanup.txt ${id}" | tee -a $log # debug info
            "${DIGCOLPROC_HOME}util/place_event.sh" flow3 cleanup.txt $id
        fi
    done

    return 0
}



#-----------------------------------------------------------------------------------------------------------------------
# call_api
# Run each api method
#-----------------------------------------------------------------------------------------------------------------------
function call_api(){
    echo "Log file: ${log}" | tee -a $log # debug info

    call_api_folders
    call_api_backup
    call_api_restore
    call_api_cleanup

    return 0
}


call_api
exit 0
