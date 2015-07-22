#!/bin/bash



#-----------------------------------------------------------------------------------------------------------------------
# exit_error
# Pass over an error
#-----------------------------------------------------------------------------------------------------------------------
function exit_error() {
    message=$1
    echo $message>>$log
    /usr/bin/sendmail --body "$log" --from "$flow_client" --to "$flow_notificationEMail" --subject "Error report for $archiveID" --mail_relay "$mail_relay" --mail_user "$mail_user" --mail_password "$mail_password" >> $log
    exit 1
}



