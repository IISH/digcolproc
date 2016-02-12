#!/bin/bash
#
# ingest.sh



#-----------------------------------------------------------------------------------------------------------------------
# Start ingest
#-----------------------------------------------------------------------------------------------------------------------
echo "Started ingest for $pid" >> $log



#-----------------------------------------------------------------------------------------------------------------------
# Is the ingest in progress?
#-----------------------------------------------------------------------------------------------------------------------
file_instruction=$fileSet/instruction.xml
if [ -f "$file_instruction" ] ; then
    exit_error "Instruction already present: $file_instruction. This may indicate the SIP is staged or the ingest is already in progress. This is not an error." 2
fi



#-----------------------------------------------------------------------------------------------------------------------
# Is there an access file ?
#-----------------------------------------------------------------------------------------------------------------------
access_file=$fileSet/.access.txt
if [ ! -f "$access_file" ] ; then
	exit_error "Access file not found: $access_file"
fi
access=$(<"$access_file")



#-----------------------------------------------------------------------------------------------------------------------
# Download the currently existing METS file
#-----------------------------------------------------------------------------------------------------------------------
wget -O "$work/mets.xml" "http://hdl.handle.net/$pid?locatt=view:mets"



#-----------------------------------------------------------------------------------------------------------------------
# Lock the folder and it's contents
#-----------------------------------------------------------------------------------------------------------------------
orgOwner=$(stat -c %u $fileSet)
orgGroup=$(stat -c %g $fileSet)
chown -R root:root $fileSet



#-----------------------------------------------------------------------------------------------------------------------
# Temporarily rename all hidden files (So Droid does not include them)
#-----------------------------------------------------------------------------------------------------------------------
while IFS=  read -r -d $'\n'; do
    f=("$REPLY")

    if [ -d "$f" ] ; then
        while IFS=  read -r -d $'\n'; do
            f2=("$REPLY")
            d2="$(dirname "$f2")"
            b2="$(basename "$f2")"
            mv "$f2" "$d2/HIDE$b2"
        done < <(find "$f" -type f | tac)
    fi

    d="$(dirname "$f")"
    b="$(basename "$f")"
    mv "$f" "$d/HIDE$b"
done < <(find ${fileSet} -name ".*" | tac)



#-----------------------------------------------------------------------------------------------------------------------
# Produce a droid analysis
#-----------------------------------------------------------------------------------------------------------------------
profile=$work/profile.droid
echo "Begin droid analysis for profile ${profile}" >> $log
droid --recurse -p $profile --profile-resources $fileSet>>$log
rc=$?
if [[ $rc != 0 ]] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "Droid profiling threw an error."
fi
if [[ ! -f $profile ]] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "Unable to find a DROID profile."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Revert renaming of all hidden files
#-----------------------------------------------------------------------------------------------------------------------
while IFS=  read -r -d $'\n'; do
    f=("$REPLY")
    d="$(dirname "$f")"
    b="$(basename "$f")"
    b_no_hide=${b:4}
    mv "$f" "$d/$b_no_hide"
done < <(find ${fileSet} -name "HIDE*" | tac)



#-----------------------------------------------------------------------------------------------------------------------
# Produce a report
#-----------------------------------------------------------------------------------------------------------------------
profile_csv=$profile.csv
droid -p $profile -f "file_name not starts 'HIDE'" --export-file $profile_csv >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "Droid reporting threw an error."
fi
if [ ! -f $profile_csv ] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "Unable to create a droid profile: ${profile_csv}"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Now extend the report with two columns: a md5 checksum and a persistent identifier
#-----------------------------------------------------------------------------------------------------------------------
profile_extended_csv=$profile.extended.csv
python ${DIGCOLPROC_HOME}/util/droid_extend_csv.py --sourcefile $profile_csv --targetfile $profile_extended_csv --na $na --fileset $fileSet --force_seq >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "Failed to extend the droid report with a PID and md5 checksum."
fi
if [[ ! -f $profile_extended_csv ]] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "Unable to make a DROID report."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Produce instruction from the report.
#-----------------------------------------------------------------------------------------------------------------------
work_instruction=$work/instruction.xml
python ${DIGCOLPROC_HOME}/util/droid_to_instruction.py --textLayerCheck -s $profile_extended_csv -t $work_instruction --objid "$pid" --access "$access" --submission_date "$datestamp" --autoIngestValidInstruction "$flow_autoIngestValidInstruction" --label "$archiveID $flow_client" --action "add" --notificationEMail "$flow_notificationEMail" --plan "StagingfileIngestLevel3,StagingfileIngestLevel2,StagingfileIngestLevel1,StagingfileBindPIDs,StagingfileIngestMaster" >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "Failed to create an instruction."
fi
if [ ! -f $work_instruction ] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "Failed to find an instruction at ${work_instruction}"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Upload the files
#-----------------------------------------------------------------------------------------------------------------------
ftp_script_base=$work/ftp.$archiveID.$datestamp
ftp_script=$ftp_script_base.files.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "mirror --reverse --delete --verbose --exclude ^\.access\.txt$ ${fileSet} /${archiveID}" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "FTP Failed"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Upload the instruction
#-----------------------------------------------------------------------------------------------------------------------
cp $work_instruction $file_instruction
ftp_script=$ftp_script_base.instruction.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "put -O /${archiveID} ${fileSet}/instruction.xml" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "FTP Failed"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Declare objid PID
#-----------------------------------------------------------------------------------------------------------------------
filepid=""
while read line
do
    IFS=, read ID PARENT_ID URI FILE_PATH NAME METHOD STATUS SIZE TYPE EXT LAST_MODIFIED EXTENSION_MISMATCH HASH FORMAT_COUNT PUID MIME_TYPE FORMAT_NAME FORMAT_VERSION PID SEQ <<< "$line"
    if [ -z "$filepid" ] && [ "$SEQ" == "\"$refSeqNr\"" ] && [[ "$FILE_PATH" != *"text"* ]] ; then
        filepid="${PID%\"}"
        filepid="${filepid#\"}"

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
                            <pid:location weight='0' href='$or/pdf/$pid' view='pdf'/> \
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
                chown -R "$orgOwner:$orgGroup" $fileSet
                echo "Message:" >> $log
                echo $soapenv >> $log
                exit_error "Error from PID webservice: $rc" >> $log
            fi
        else
             echo "Message send to PID webservice: $soapenv" >> $log
        fi
    fi
done < $profile_extended_csv
if [ -z "$filepid" ] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "No PID found for binding the PID of the objid."
else
    echo "$filepid" >> "$work/filepid.txt"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Ingest finished
#-----------------------------------------------------------------------------------------------------------------------
chown -R "$orgOwner:$orgGroup" $fileSet
echo "Finished ingest for $pid" >> $log