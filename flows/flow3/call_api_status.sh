#!/bin/bash



#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
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



#-----------------------------------------------------------------------------------------------------------------------
# call_api_status
# Use the API to sent status and message updates
#-----------------------------------------------------------------------------------------------------------------------
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

	#
	if [ -z "$message" ]; then
		if [ $status -eq 40 ] || [ $status -eq 70 ] || [ $status -eq 100 ]; then
			message="Requested";
		elif [ $status -eq 20 ] || [ $status -eq 50 ] || [ $status -eq 80 ] || [ $status -eq 110 ]; then
			message="Processing";
		elif [ $status -eq 30 ] || [ $status -eq 60 ] || [ $status -eq 90 ] || [ $status -eq 120 ]; then
			message="Done";
		else
			message="ok";
		fi
	fi

    # Update the status using the 'status' web service
    request_data="pid=${pid}&status=${status}&failure=${failure}&access_token=${acquisition_database_access_token}&message=${message}"
    endpoint="${acquisition_database}/service/status"
    echo "endpoint=${endpoint}">>$log
    echo "request_data=${request_data}">>$log
    rc=$(curl -o /dev/null -s --insecure --max-time 5 -w "%{http_code}" --data "$request_data" "$endpoint")
    if [[ $rc != 200 ]] ; then
        echo "Error when contacting ${endpoint} got statuscode ${rc}">>$log
        exit 1
    fi
    return 0
}


function call_api_manifest() {
    pid=$1
    archiveID=$2
    file=$3
    endpoint="${acquisition_database}/service/manifest"
    rc=$(curl -o /dev/null -s --insecure --max-time 180 -w "%{http_code}" --form "access_token=${acquisition_database_access_token}" --form "pid=${pid}" --form manifest_csv="@${file};type=text/csv;filename=manifest.${archiveID}.csv" "$endpoint")
    if [[ $rc != 200 ]] ; then
        echo "Error when contacting ${endpoint} got statuscode ${rc}">>$log
        exit 1
    fi
    return 0
}

#-----------------------------------------------------------------------------------------------------------------------
# exit_error
# Pass over an error
#-----------------------------------------------------------------------------------------------------------------------
function exit_error() {
    pid=$1
    status=$2
    message=$3
    call_api_status "$pid" "$status" true "$message"

    echo $message >> $log
    /usr/bin/sendmail --body "$log" --from "$flow_client" --to "$flow_notificationEMail" --subject "Error report for $archiveID" --mail_relay "$mail_relay" --mail_user "$mail_user" --mail_password "$mail_password" >> $log

    exit 1
}