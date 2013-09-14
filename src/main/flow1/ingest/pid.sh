#!/bin/bash
#
# pid.sh
#
# Declare the archive PID; and
# declare and bind our ObjId PIDs
#

echo "Declare pids...">>$log

# Example line is
# 1,1,/ARCH00518/Tiff/1/1_0005.tif,/ARCH00518/Jpeg/1/1_0005.jpg,5,10622/A3EF7419-A1D8-4698-8369-F62ADAEC703E
file=/tmp/pid.log
while read line
do
    while IFS=, read objnr ID master jpeg volgnr PID; do
        if [[ $volgnr == 2 ]]; then
            objid=$na/$archiveID.$ID
            soapenv="<?xml version='1.0' encoding='UTF-8'?>  \
    <soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:pid='http://pid.socialhistoryservices.org/'>  \
        <soapenv:Body> \
            <pid:UpsertPidRequest> \
                <pid:na>$na</pid:na> \
                <pid:handle> \
                    <pid:pid>$objid</pid:pid> \
                    <pid:locAtt> \
                            <pid:location weight='1' href='$catalog/$archiveID/ArchiveContentList#$ID'/> \
                            <pid:location weight='0' href='$catalog/$archiveID/ArchiveContentList#$ID' view='catalog'/> \
                            <pid:location weight='0' href='$or/mets/$objid' view='mets'/> \
                            <pid:location weight='0' href='$or/pdf/$objid' view='pdf'/> \
                            <pid:location weight='0' href='$or/file/master/$PID' view='master'/> \
                            <pid:location weight='0' href='$or/file/level1/$PID' view='level1'/> \
                            <pid:location weight='0' href='$or/file/level2/$PID' view='level2'/> \
                            <pid:location weight='0' href='$or/file/level3/$PID' view='level3'/> \
                        </pid:locAtt> \
                </pid:handle> \
            </pid:UpsertPidRequest> \
        </soapenv:Body> \
    </soapenv:Envelope>"

    echo "Sending $pid"
    wget -O $file --header="Content-Type: text/xml" \
        --header="Authorization: oauth $pidwebserviceKey" --post-data "$soapenv" \
        --no-check-certificate $pidwebserviceEndpoint >> $log

    pidCheck=$(php $global_home/pid.php -l $file)
    rm $file
    if [ "${pidCheck}" != "${pid^^}" ] ; then
        echo "ERROR: Pid not returned by webservice"
    fi

        fi
    done
done < $cf



# The main archival ID
# This will bind to the catalog as well.
pid=$na/$archiveID
soapenv="<?xml version='1.0' encoding='UTF-8'?>  \
    <soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:pid='http://pid.socialhistoryservices.org/'>  \
        <soapenv:Body> \
            <pid:UpsertPidRequest> \
                <pid:na>$na</pid:na> \
                <pid:handle> \
                    <pid:pid>$pid</pid:pid> \
                    <pid:locAtt> \
                            <pid:location weight='1' href='$catalog/$archiveID'/> \
                            <pid:location weight='0' href='$catalog/$archiveID' view='catalog'/> \
                            <pid:location weight='0' href='$oai?verb=GetRecord&amp;identifier=oai:socialhistoryservices.org:$na/$archiveID&amp;metadataPrefix=ead' view='ead'/> \
                            <pid:location weight='0' href='$or/file/master/$PID' view='master'/> \
                            <pid:location weight='0' href='$or/file/level2/$PID' view='level2'/> \
                            <pid:location weight='0' href='$or/file/level3/$PID' view='level3'/>
                            <pid:location weight='0' href='$or/file/level1/$PID' view='level1'/> \
                        </pid:locAtt> \
                </pid:handle> \
            </pid:UpsertPidRequest> \
        </soapenv:Body> \
    </soapenv:Envelope>"
wget -O $file --header="Content-Type: text/xml" \
        --header="Authorization: oauth $pidwebserviceKey" --post-data "$soapenv" \
        --no-check-certificate $pidwebserviceEndpoint >> $log

    pidCheck=$(php $global_home/pid.php -l $file)
    rm $file
    if [ "${pidCheck}" != "${pid^^}" ] ; then
        echo "ERROR: Pid not returned by webservice"
    fi

echo "Done file pid declarations.">>$log