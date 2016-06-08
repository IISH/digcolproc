#!/bin/bash
#
# run.sh
#
# Usage:
# run.sh [na] [folder name]
#

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh



#-----------------------------------------------------------------------------------------------------------------------
# Start the bind
#-----------------------------------------------------------------------------------------------------------------------
pidLocation=""
if [ ! -z "$catalogUrl" ] ; then
    pidLocation="<pid:location weight='1' href='$catalogUrl'/> <pid:location weight='0' href='$catalogUrl' view='catalog'/>"
else
    pidLocation="<pid:location weight='1' href='$or/file/master/$pid'/>"
fi

soapenv="<?xml version='1.0' encoding='UTF-8'?>  \
<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:pid='http://pid.socialhistoryservices.org/'>  \
    <soapenv:Body> \
        <pid:UpsertPidRequest> \
            <pid:na>$na</pid:na> \
            <pid:handle> \
                <pid:pid>$pid</pid:pid> \
                <pid:locAtt> \
                    $pidLocation \
                    <pid:location weight='0' href='$or/file/master/$pid' view='mets'/> \
                </pid:locAtt> \
            </pid:handle> \
        </pid:UpsertPidRequest> \
    </soapenv:Body> \
</soapenv:Envelope>"

echo "Sending $objid" >> $log
if [ "$environment" == "production" ] ; then
    wget -O /dev/null --header="Content-Type: text/xml" \
        --header="Authorization: oauth $pidwebserviceKey" --post-data "$soapenv" \
        --no-check-certificate $pidwebserviceEndpoint

    rc=$?
    if [[ $rc != 0 ]]; then
        echo "Message:" >> $log
        echo $soapenv >> $log
        exit_error "Error from PID webservice: $rc" >> $log
    fi
else
     echo "Message send to PID webservice: $soapenv" >> $log
fi



#-----------------------------------------------------------------------------------------------------------------------
# End job
#-----------------------------------------------------------------------------------------------------------------------
echo "Done. All went well at this side." >> $log
exit 0