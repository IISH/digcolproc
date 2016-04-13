#!/bin/bash



#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
FOLDER=10
BACKUP=20
RESTORE=30
STAGINGAREA=40
SOR=50
CLEANUP=60

REQUESTED=1
RUNNING=2
FINISHED=3
FAILED=4

#-----------------------------------------------------------------------------------------------------------------------
# call_api_status
# Use the API to sent status and message updates
#-----------------------------------------------------------------------------------------------------------------------
function call_api_status() {
    pid=$1
    status=$2
    subStatus=$3
    message="$4"

    if [ -z "$pid" ]; then
        echo "Error: pid argument is empty.">>$log
        exit 1
    fi
    if [ -z "$status" ]; then
        echo "Error: status argument is empty.">>$log
        exit 1
    fi
    if [ -z "$subStatus" ]; then
        echo "Error: subStatus argument is empty.">>$log
        exit 1
    fi

	if [ -z "$message" ]; then
		if [ $subStatus -eq $REQUESTED ]; then
			message="Requested";
		elif [ $subStatus -eq $RUNNING ]; then
			message="Processing";
		elif [ $status -eq $FINISHED ]; then
			message="Done";
        elif [ $status -eq $FAILED ]; then
			message="Failure";
		else
			message="OK";
		fi
	fi

    # Update the status using the 'status' web service
    request_data="pid=${pid}&status=${status}&subStatus=${subStatus}&access_token=${acquisition_database_access_token}&message=${message}"
    endpoint="${acquisition_database}/service/status"
    echo "endpoint=${endpoint}">>$log
    echo "request_data=${request_data}">>$log
    rc=$(curl -o /dev/null -s --insecure --max-time 5 --data "$request_data" "$endpoint")
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
    rc=$(curl -o /dev/null -s --insecure --max-time 180 --form "access_token=${acquisition_database_access_token}" --form "pid=${pid}" --form manifest_csv="@${file};type=text/csv;filename=manifest.${archiveID}.csv" "$endpoint")
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
    call_api_status "$pid" "$status" $FAILED "$message"

    echo $message >> $log
    /usr/bin/sendmail --body "$log" --from "$flow_client" --to "$flow_notificationEMail" --subject "Error report for $archiveID" --mail_relay "$mail_relay" --mail_user "$mail_user" --mail_password "$mail_password" >> $log

    exit 1
}