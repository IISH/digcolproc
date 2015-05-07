#!/bin/bash

# run.sh
#
# Usage:
# run.sh [na] [folder name]
#
# This script ingests a fileSet
# /a/b/c/10622/offloader/BULK12345



#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh
STATUS=$UPLOADING_TO_PERMANENT_STORAGE
pid=$na/$archiveID



#-----------------------------------------------------------------------------------------------------------------------
# Commence job. Tell what we are doing
#-----------------------------------------------------------------------------------------------------------------------
call_api_status $pid ${STATUS}



#-----------------------------------------------------------------------------------------------------------------------
# Make sure we do not have an instruction already there.
#-----------------------------------------------------------------------------------------------------------------------
file_instruction=$fileSet/instruction.xml
if [ -f "$file_instruction" ] ; then
    exit_error "$pid" ${STATUS} "Instruction already present: ${file_instruction}. This may indicate the SIP is staged \
    or the ingest is already in progress."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Lock the folder and it's contents
#-----------------------------------------------------------------------------------------------------------------------
chown -R root:root $fileSet



#-----------------------------------------------------------------------------------------------------------------------
# Produce a droid analysis. Remove the old profile if it is there.
#-----------------------------------------------------------------------------------------------------------------------
if [ -f $fileSet/manifest.csv ] ; then rm $fileSet/manifest.csv ; fi
profile=$work/profile.droid
droid --recurse -p $profile --profile-resources $fileSet>>$log
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "$pid" ${STATUS} "Droid profiling threw an error."
fi



#-----------------------------------------------------------------------------------------------------------------------
# produce a report.
#-----------------------------------------------------------------------------------------------------------------------
profile_csv=$profile.csv
droid -p $profile --export-file $profile_csv >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "$pid" ${STATUS} "Droid reporting threw an error."
fi
if [ ! -f $profile_csv ] ; then
	exit_error "$pid" ${STATUS} "Unable to create a droid profile: ${profile_csv}"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Now extend the report with two columns: a md5 checksum and a persistent identifier
#-----------------------------------------------------------------------------------------------------------------------
profile_extended_csv=$profile.extended.csv
echo "RUN: python ${DIGCOLPROC_HOME}/util/droid_extend_csv.py --sourcefile $profile_csv --targetfile $profile_extended_csv --na $na --fileset $fileSet >> $log " >> $log
python ${DIGCOLPROC_HOME}/util/droid_extend_csv.py --sourcefile $profile_csv --targetfile $profile_extended_csv --na $na --fileset $fileSet >> $log
rc=$?
if [[ $rc != 0 ]] ; then
	exit_error "$pid" ${STATUS} "Error flow3-ingest-a3c2d4. Failed to extend the droid report with a PID and md5 checksum."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Create a mets document
#-----------------------------------------------------------------------------------------------------------------------
manifest=${fileSet}/manifest.xml
python ${DIGCOLPROC_HOME}/util/droid_to_mets.py --sourcefile $profile_extended_csv --targetfile $manifest --objid "$pid"
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "$pid" ${STATUS} "Failed to create a mets document."
fi
if [ ! -f $manifest ] ; then
    exit_error "$pid" ${STATUS} "Failed to find a mets file at ${manifest}"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Add the mets file to the manifest.csv, in order for it to be in the xml instruction
#-----------------------------------------------------------------------------------------------------------------------
md5_hash=$(md5sum $manifest | cut -d ' ' -f 1)
echo ""","1","file:/${archiveID}/","/${archiveID}/manifest.xml","manifest.xml","METHOD","$STATUS","SIZE","File","xml","","EXTENSION_MISMATCH","${md5_hash}","FORMAT_COUNT","PUID","application/xml","Xml Document","FORMAT_VERSION","${pid}",""">>$profile_extended_csv



#-----------------------------------------------------------------------------------------------------------------------
# Produce instruction from the report.
#-----------------------------------------------------------------------------------------------------------------------
work_instruction=$work/instruction.xml
python ${DIGCOLPROC_HOME}/util/droid_to_instruction.py -s $profile_extended_csv -t $work_instruction --objid "$pid" --access "$flow_access" --submission_date "$datestamp" --autoIngestValidInstruction "$flow_autoIngestValidInstruction" --label "$archiveID $flow_client" --action "add" --notificationEMail "$flow_notificationEMail" --plan "StagingfileBindPIDs,StagingfileIngestMaster" >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "$pid" ${STATUS} "Failed to create an instruction."
fi
if [ ! -f $work_instruction ] ; then
    exit_error "$pid" ${STATUS} "Failed to find an instruction at ${file_instruction}"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Now start the reverse mirror
#-----------------------------------------------------------------------------------------------------------------------
ftp_script_base=${work}/ftp.$archiveID.$datestamp
ftp_script=${ftp_script_base}.files.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "mirror --reverse --delete --verbose ${fileSet} /${archiveID}" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "$pid" ${STATUS} "FTP error with uploading the files."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Upload the instruction
#-----------------------------------------------------------------------------------------------------------------------
mv $work_instruction $file_instruction
ftp_script=$ftp_script_base.instruction.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "put -O /${archiveID} ${file_instruction}" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "$pid" ${STATUS} "FTP error with uploading the object repository instruction."
fi


#-----------------------------------------------------------------------------------------------------------------------
# Bind the PID
#-----------------------------------------------------------------------------------------------------------------------
soapenv="<?xml version='1.0' encoding='UTF-8'?>  \
		<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:pid='http://pid.socialhistoryservices.org/'>  \
			<soapenv:Body> \
				<pid:UpsertPidRequest> \
					<pid:na>$na</pid:na> \
					<pid:handle> \
						<pid:pid>$pid</pid:pid> \
						<pid:locAtt> \
								<pid:location weight='1' href='$or/metadata/$pid'/> \
								<pid:location weight='0' href='$or/file/master/$pid' view='master'/> \
							</pid:locAtt> \
					</pid:handle> \
				</pid:UpsertPidRequest> \
			</soapenv:Body> \
		</soapenv:Envelope>"
echo "Binding pid ${pid} with ${soapenv}" >> $log
rc=$?
wget -O /dev/null --header="Content-Type: text/xml" \
    --header="Authorization: oauth $pidwebserviceKey" --post-data "$soapenv" \
    --no-check-certificate $pidwebserviceEndpoint
if [[ $rc != 0 ]] ; then
    exit_error "$pid" ${STATUS} "The submission to the object repostory succeeded. However we failed to bind the pid to the url of the manifest."
fi


#-----------------------------------------------------------------------------------------------------------------------
# End job
#-----------------------------------------------------------------------------------------------------------------------
echo "Done. ALl went well at this side." >> $log
call_api_status $pid $MOVED_TO_PERMANENT_STORAGE
exit 0
