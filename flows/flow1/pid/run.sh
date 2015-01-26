#!/bin/bash
#
# pid.sh
#
# Declare the archive PID; and
# declare and bind our ObjId PIDs
#

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"

echo "Start preparing ingest...">>$log
cf=$fileSet/.validate/concordanceValidWithPID.csv
if [ ! -f $cf ] ; then
    echo "Error... did not find $cf">>$log
    echo "Is the dataset validated ?">>$log
    exit -1
fi

echo "Declare pids...">>$log

# Example line is
# 1,1,/ARCH00518/Tiff/1/1_0005.tif,/ARCH00518/Jpeg/1/1_0005.jpg,5,10622/A3EF7419-A1D8-4698-8369-F62ADAEC703E
lastpid=""
while read line
do
    IFS=, read objnr ID master jpeg volgnr PID <<< "$line"
    if [[ $volgnr -eq 2 ]]; then
        lastpid=$PID
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


        echo "Sending $objid" >> $log
        wget -O /dev/null --header="Content-Type: text/xml" \
            --header="Authorization: oauth $pidwebserviceKey" --post-data "$soapenv" \
            --no-check-certificate $pidwebserviceEndpoint

        rc=$?
        if [[ $rc != 0 ]]; then
            echo "Error from PID webservice: $rc">>$log
            echo $soapenv >> $log
            cat $file >> $log
        fi
    fi
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
								<pid:location weight='0' href='$or/file/master/$lastpid' view='master'/> \
								<pid:location weight='0' href='$or/file/level1/$lastpid' view='level1'/> \
								<pid:location weight='0' href='$or/file/level2/$lastpid' view='level2'/> \
								<pid:location weight='0' href='$or/file/level3/$lastpid' view='level3'/> \
							</pid:locAtt> \
					</pid:handle> \
				</pid:UpsertPidRequest> \
			</soapenv:Body> \
		</soapenv:Envelope>"
	
	echo "Sending $pid" >> $log
	wget -O /dev/null --header="Content-Type: text/xml" \
        --header="Authorization: oauth $pidwebserviceKey" --post-data "$soapenv" \
        --no-check-certificate $pidwebserviceEndpoint

    rc=$?
	if [[ $rc != 0 ]]; then
		echo "Error from PID webservice: $rc">>$log
		echo $soapenv >> $log
	fi

echo "Done file pid declarations.">>$log