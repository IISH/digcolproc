#!/bin/bash


NEW_DIGITAL_MATERIAL_COLLECTION=10
FOLDER_CREATION_RUNNING=20
FOLDER_CREATED=30

MATERIAL_UPLOADED=40
BACKUP_RUNNING=50
BACKUP_FINISHED=60

READY_FOR_RESTORE=70
RESTORE_RUNNING=80
RESTORE_FINISHED=90

READY_FOR_PERMANENT_STORAGE=100
UPLOADING_TO_PERMANENT_STORAGE=110
MOVED_TO_PERMANENT_STORAGE=120


function call_api_status() {
    pid=$1
    status=$2
    failure=$3
    message="$4"

    if [ -z "$pid" ]; then
        echo "Error: pid argument is empty.">>$log
        exit 1
    fi
    if [ -z "$status" ]; then
        echo "Error: status argument is empty.">>$log
        exit 1
    fi
    if [ -z "$failure" ]; then
        failure=false
    fi
    if [ -z "$message" ]; then
        message="ok"
    fi

    # Update the status using the 'status' web service
    request_data="pid=${pid}&status=${status}&failure=${failure}&access_token=${acquisition_database_access_token}&message=${message}"
    echo "request_data=${request_data}">>$log
    curl --insecure --data "$request_data" "${acquisition_database}/service/status"
    return $?
}