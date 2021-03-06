#!/bin/bash
#
# run.sh
#
# Retrieve the EAD from the OAI2 server
# Obtain the item numbers in: //ead:did/ead:unitid/4074
# Bind the PID and qualifiers to the expected resolvable URLs


#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh


#-----------------------------------------------------------------------------------------------------------------------
# Download the EAD file
#-----------------------------------------------------------------------------------------------------------------------
file="${work}/${archiveID}.xml"
pid="${na}/${archiveID}"
oai_request="${oai}?verb=GetRecord&identifier=oai:socialhistoryservices.org:${pid}&metadataPrefix=ead"
rm $file
wget --no-check-certificate -O "$file" "$oai_request"
if [ ! -f $file ]
then
    echo "Unable to get ${oai_request} to ${file}">>$log
    exit 1
fi


#-----------------------------------------------------------------------------------------------------------------------
# Pull out the unitid values. Create a concordance list as used by the PID bind procedure.
#-----------------------------------------------------------------------------------------------------------------------
file_concordancetable="${work}/${archiveID}_concordancetable.csv"
python ${DIGCOLPROC_HOME}/util/xslt_transformer.py --xml_file="$file" --xsl_file="create_concordancetable.xsl" --result_file="$file_concordancetable" >> $log 2>&1
rc=$?
if [[ $rc != 0 ]] ; then
    echo "xslt_transformer.py threw an error ${rc}">>$log
    exit 1
fi
if [ ! -f $file_concordancetable ]
then
    echo "Unable to create ${file_concordancetable}">>$log
    exit 1
fi
echo "" >> "$file_concordancetable"


#-----------------------------------------------------------------------------------------------------------------------
# For each unitid in the csv, append the second item.
#-----------------------------------------------------------------------------------------------------------------------
while read line
do
    IFS=, read Inventarisnummer <<< "$line"

    mets_item="${or}/file/master/${na}/${archiveID}.${Inventarisnummer}" # e.g. http://disseminate.objectrepository.org/file/master/10622/ARCH00720.1
    file_item="${work}/${archiveID}.${Inventarisnummer}.xml"
    wget --no-check-certificate -O "$file_item" "$mets_item"
    pid=$(python ${DIGCOLPROC_HOME}/util/xslt_transformer.py --xml_file="$mets_item" --xsl_file="get_item_pid.xsl")
    rm "$file_item"

    if [ -z "$pid" ]
    then
        echo "Could not get a PID for Inventarisnummer ${Inventarisnummer}.">>$log
        echo "Does not seem to be in the SOR">>$log
    else
        last_pid="$pid"
    fi

    objid="${na}/${archiveID}.${Inventarisnummer}"
    if [ -z "$last_pid" ]
    then
        soapenv="<?xml version='1.0' encoding='UTF-8'?>  \
            <soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:pid='http://pid.socialhistoryservices.org/'>  \
                <soapenv:Body> \
                    <pid:UpsertPidRequest> \
                        <pid:na>$na</pid:na> \
                        <pid:handle> \
                            <pid:pid>$objid</pid:pid> \
                            <pid:locAtt> \
                                    <pid:location weight='1' href='$catalog/$archiveID/ArchiveContentList#$Inventarisnummer'/> \
                                    <pid:location weight='0' href='$catalog/$archiveID/ArchiveContentList#$Inventarisnummer' view='catalog'/> \
                                </pid:locAtt> \
                        </pid:handle> \
                    </pid:UpsertPidRequest> \
                </soapenv:Body> \
            </soapenv:Envelope>"
    else
        soapenv="<?xml version='1.0' encoding='UTF-8'?>  \
            <soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:pid='http://pid.socialhistoryservices.org/'>  \
                <soapenv:Body> \
                    <pid:UpsertPidRequest> \
                        <pid:na>$na</pid:na> \
                        <pid:handle> \
                            <pid:pid>$objid</pid:pid> \
                            <pid:locAtt> \
                                    <pid:location weight='1' href='$catalog/$archiveID/ArchiveContentList#$Inventarisnummer'/> \
                                    <pid:location weight='0' href='$catalog/$archiveID/ArchiveContentList#$Inventarisnummer' view='catalog'/> \
                                    <pid:location weight='0' href='$or/file/master/$objid' view='mets'/> \
                                    <pid:location weight='0' href='$or/pdf/$objid' view='pdf'/> \
                                    <pid:location weight='0' href='$or/file/master/$pid' view='master'/> \
                                    <pid:location weight='0' href='$or/file/level1/$pid' view='level1'/> \
                                    <pid:location weight='0' href='$or/file/level2/$pid' view='level2'/> \
                                    <pid:location weight='0' href='$or/file/level3/$pid' view='level3'/> \
                                </pid:locAtt> \
                        </pid:handle> \
                    </pid:UpsertPidRequest> \
                </soapenv:Body> \
            </soapenv:Envelope>"
    fi


    echo "Sending $objid" >> $log
    wget -O /dev/null --header="Content-Type: text/xml" \
        --header="Authorization: bearer $pidwebserviceKey" --post-data "$soapenv" \
        --no-check-certificate $pidwebserviceEndpoint

    rc=$?
    if [[ $rc != 0 ]]; then
        echo "Error from PID webservice: $rc">>$log
        echo $soapenv >> $log
        cat $file >> $log
    fi
done < $file_concordancetable


if [ ! -z "$last_pid" ]
then
    # The main archival ID
	# This will bind to the catalog as well.
	pid="$na/$archiveID"
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
								<pid:location weight='0' href='$or/file/master/$last_pid' view='master'/> \
								<pid:location weight='0' href='$or/file/level1/$last_pid' view='level1'/> \
								<pid:location weight='0' href='$or/file/level2/$last_pid' view='level2'/> \
								<pid:location weight='0' href='$or/file/level3/$last_pid' view='level3'/> \
							</pid:locAtt> \
					</pid:handle> \
				</pid:UpsertPidRequest> \
			</soapenv:Body> \
		</soapenv:Envelope>"

	echo "Sending $pid" >> $log
	wget -O /dev/null --header="Content-Type: text/xml" \
        --header="Authorization: bearer $pidwebserviceKey" --post-data "$soapenv" \
        --no-check-certificate $pidwebserviceEndpoint

    rc=$?
	if [[ $rc != 0 ]]; then
		echo "Error from PID webservice: $rc">>$log
		echo $soapenv >> $log
	fi
fi



echo "I think we are done...">>$log
exit 0