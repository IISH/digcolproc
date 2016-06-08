#!/bin/bash
#
# bind_mets_ead_item.sh



#-----------------------------------------------------------------------------------------------------------------------
# Preperations
#-----------------------------------------------------------------------------------------------------------------------
objnr=$1
ID=$2

catalogUrl="$catalog/$archiveID/ArchiveContentList#$ID"
work=$work/$archiveID.$objnr
pid=$na/$archiveID.$ID
fileSet=$fileSet/$archiveID.$objnr
orgArchiveID=$archiveID
archiveID=$(basename "$fileSet")
log="${work}/${datestamp}T${time}.log"

if [ ! -d "$work" ] ; then
    mkdir -p $work
fi

echo "Starting bind METS for item $ID with objnr $objnr" >> $log
echo "Item $ID : catalogUrl: $catalogUrl" >> $log
echo "Item $ID : work : $work" >> $log
echo "Item $ID : pid : $pid" >> $log
echo "Item $ID : fileSet : $fileSet" >> $log
echo "Item $ID : archiveID : $archiveID" >> $log
echo "Item $ID : log : $log" >> $log



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
echo "Bind METS finished for $pid" >> $log
exit 0