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
# Determine access value, default is 'open'
# When we check for an access file... use the parent folder also.
#-----------------------------------------------------------------------------------------------------------------------
for folder in "$fileSet" $(dirname "$fileSet")
do
    access_file="${folder}/.access.txt"
    if [ -f "$access_file" ]
    then
        access=$(<"$access_file")
        break
    fi
done
if [ -z "$access" ] ; then
  access="open"
  echo "$access" > ${fileSet}/.access.txt
fi


#-----------------------------------------------------------------------------------------------------------------------
# Transform to MARC directory layout
#-----------------------------------------------------------------------------------------------------------------------
profile=$fs_parent/.work/$archiveID/validate/profile.csv
python ${DIGCOLPROC_HOME}/util/concordance_to_directory.py --concordance $cf --droid $profile --fileset $fileSet --access $access >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "Failed to transform the directory layout."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Start ingest and METS creation for each item
#-----------------------------------------------------------------------------------------------------------------------
pids=()
i=0
while read line
do
    IFS=, read objnr ID <<< "$line"

    (source ./ingest_ead_item.sh "$objnr" "$ID")

    rc=$?
    if [[ $rc != 0 && $rc != 2 ]] ; then
        exit_error "At least one of the items failed to ingest." >> $log
    fi
done < <(python ${DIGCOLPROC_HOME}/util/concordance_to_list.py --concordance "$cf")



#-----------------------------------------------------------------------------------------------------------------------
# Update the EAD
#-----------------------------------------------------------------------------------------------------------------------
eadFile=$fileSet/$archiveID.xml
if [ ! -f $eadFile ] ; then
    echo "Warning: Unable to find the EAD document at $eadFile" >> $log
else
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
fi



#-----------------------------------------------------------------------------------------------------------------------
# Declare PID for complete archive
#-----------------------------------------------------------------------------------------------------------------------
filepidtxt=$(find "$work" -name filepid.txt | sort | head -1)
filepid=$(<"$filepidtxt")
if [ -z "$filepid" ] ; then
    message="No PID found for binding the PID of the archive. In case of a merge, this is ok!"
    echo $message >> $log
    /usr/bin/sendmail --body "$log" --from "$flow_client" --to "$flow_notificationEMail" --subject "Error report for $archiveID" --mail_relay "$mail_relay" --mail_user "$mail_user" --mail_password "$mail_password" >> $log
else
    objid=$na/$archiveID
    soapenv="<?xml version='1.0' encoding='UTF-8'?>  \
    <soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:pid='http://pid.socialhistoryservices.org/'>  \
        <soapenv:Body> \
            <pid:UpsertPidRequest> \
                <pid:na>$na</pid:na> \
                <pid:handle> \
                    <pid:pid>$objid</pid:pid> \
                    <pid:locAtt> \
                        <pid:location weight='1' href='$catalog/$archiveID'/> \
                        <pid:location weight='0' href='$catalog/$archiveID' view='catalog'/> \
                        <pid:location weight='0' href='$oai?verb=GetRecord&amp;identifier=oai:socialhistoryservices.org:$na/$archiveID&amp;metadataPrefix=ead' view='ead'/> \
                        <pid:location weight='0' href='$or/file/master/$filepid' view='master'/> \
                        <pid:location weight='0' href='$or/file/level1/$filepid' view='level1'/> \
                        <pid:location weight='0' href='$or/file/level2/$filepid' view='level2'/> \
                        <pid:location weight='0' href='$or/file/level3/$filepid' view='level3'/> \
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
fi



#-----------------------------------------------------------------------------------------------------------------------
# Start the remove procedure
#-----------------------------------------------------------------------------------------------------------------------
# TODO: source ../remove.sh



#-----------------------------------------------------------------------------------------------------------------------
# End job
#-----------------------------------------------------------------------------------------------------------------------
echo "Done. All went well at this side." >> $log
exit 0