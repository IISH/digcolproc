#!/bin/bash
#
# run.sh
#



#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh



#-----------------------------------------------------------------------------------------------------------------------
# Is the dataset validated?
#-----------------------------------------------------------------------------------------------------------------------
echo "Start preparing ingest...">>$log
cf=$fs_parent/.work/$archiveID/validate/concordanceValid.csv
if [ ! -f $cf ] ; then
    exit_error "Error... did not find $cf Is the dataset validated?"
fi

md5check=$(md5sum $fileSet/$archiveID.csv)
md5=$(cat $fs_parent/.work/$archiveID/validate/$archiveID.csv.md5)
if [ "$md5" != "$md5check" ] ; then
    exit_error "The CSV file seems to have been changed after it was validated and must be re-validated first."
fi



#-----------------------------------------------------------------------------------------------------------------------
# TODO: Transform to flow 4 directory layout?
#-----------------------------------------------------------------------------------------------------------------------



#-----------------------------------------------------------------------------------------------------------------------
# Determine access value, default is 'open'
#-----------------------------------------------------------------------------------------------------------------------
access_file=$fileSet/.access.txt
if [ -f "$access_file" ] ; then
	access=$(<"$access_file")
fi
if [ -z "$access" ] ; then
  access="open"
  echo "$access" > ${fileSet}/.access.txt
fi



#-----------------------------------------------------------------------------------------------------------------------
# Start ingest for each item
#-----------------------------------------------------------------------------------------------------------------------
curFileSet=$fileSet
curArchiveID=$archiveID
curWork=$work
while read line
do
    IFS=, read objnr ID <<< "$line"

    fileSet=$curFileSet/$curArchiveID.$objnr
    archiveID=$(basename "$fileSet")
    catalogUrl="$catalog/$curArchiveID/ArchiveContentList#$ID"
    work=$curWork/$curArchiveID.$objnr
    pid=$na/$curArchiveID.$ID

    echo "fileSet: $fileSet" >> $log
    echo "archiveID: $archiveID" >> $log
    echo "catalogUrl: $catalogUrl" >> $log
    echo "work: $work" >> $log
    echo "pid: $pid" >> $log

    if [ ! -d "$work" ] ; then
        mkdir $work
    fi

    if [ -d "$fileSet/jpeg" ] ; then
        mv $fileSet/jpeg $fileSet/.level1
    fi

    file_instruction=$fileSet/instruction.xml
    if [ -f "$file_instruction" ] ; then
        exit_error "Instruction already present: $file_instruction. This may indicate the SIP is staged or the ingest is already in progress. This is not an error."
    fi

    source ../ingest.sh
done < <(python ${DIGCOLPROC_HOME}/util/concordance_to_list.py --concordance "$cf")
fileSet=$curFileSet
archiveID=$curArchiveID
work=$curWork


#-----------------------------------------------------------------------------------------------------------------------
# Declare PID for complete archive
#-----------------------------------------------------------------------------------------------------------------------
objid=$na/$archiveID
soapenv="<?xml version='1.0' encoding='UTF-8'?>  \
<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:pid='http://pid.socialhistoryservices.org/'>  \
    <soapenv:Body> \
        <pid:UpsertPidRequest> \
            <pid:na>$na</pid:na> \
            <pid:handle> \
                <<pid:pid>$objid</pid:pid> \
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

echo "Sending $objid" >> $log
wget -O /dev/null --header="Content-Type: text/xml" \
    --header="Authorization: oauth $pidwebserviceKey" --post-data "$soapenv" \
    --no-check-certificate $pidwebserviceEndpoint

rc=$?
if [[ $rc != 0 ]]; then
    echo "Message:" >> $log
    echo $soapenv >> $log
    exit_error "Error from PID webservice: $rc" >> $log
fi



#-----------------------------------------------------------------------------------------------------------------------
# Update the EAD
#-----------------------------------------------------------------------------------------------------------------------
eadFile=$fileSet/$archiveID.xml
if [ ! -f $eadFile ] ; then
    exit_error "Unable to find the EAD document at $eadFile The ingest was interrupted."
fi

archiveIDs=$fs_parent/.work/$archiveID/validate/archiveIDs.xml
if [ ! -f $archiveIDs ] ; then
    exit_error "Unable to find the archiveIDs file at $archiveIDs The ingest was interrupted."
fi

ead=$work/$archiveID.xml
groovy ${DIGCOLPROC_HOME}util/ead.groovy "$eadFile" "$archiveIDs" $ead >> $log
if [ -f $ead ] ; then
    echo "See the EAD with added daoloc elements at" >> $log
    $ead >> $log
else
    exit_error "Unable to add daoloc elements to $ead"
fi



#-----------------------------------------------------------------------------------------------------------------------
# End job
#-----------------------------------------------------------------------------------------------------------------------
echo "Done. All went well at this side." >> $log
exit 0