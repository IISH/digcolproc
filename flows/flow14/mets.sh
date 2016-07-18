#!/bin/bash
#
# mets.sh



#-----------------------------------------------------------------------------------------------------------------------
# Start METS creation
#-----------------------------------------------------------------------------------------------------------------------
echo "Started creation of METS for $pid" >> $log


#-----------------------------------------------------------------------------------------------------------------------
# Is there an access file ?
#-----------------------------------------------------------------------------------------------------------------------
access_file=$fileSet/.access.txt
if [ ! -f "$access_file" ] ; then
	exit_error "Access file not found: $access_file"
fi
access=$(<"$access_file")



#-----------------------------------------------------------------------------------------------------------------------
# Create the METS manifest
#-----------------------------------------------------------------------------------------------------------------------
manifest=$fileSet/manifest.xml
python ${DIGCOLPROC_HOME}/util/flow14_to_mets.py --droid $profile_extended_csv --targetfile $manifest --objid "$pid" --access "$access" >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "Failed to create a METS file."
fi
if [ ! -f $manifest ] ; then
    exit_error "Failed to find a METS file at $manifest"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Create a new droid report with just the METS, in order for it to be in the XML instruction
#-----------------------------------------------------------------------------------------------------------------------
md5_hash=$(md5sum $manifest | cut -d ' ' -f 1)
profile_manifest=$work/profile_manifest.csv
echo "ID,PARENT_ID,URI,FILE_PATH,NAME,METHOD,STATUS,SIZE,TYPE,EXT,LAST_MODIFIED,EXTENSION_MISMATCH,HASH,FORMAT_COUNT,PUID,MIME_TYPE,FORMAT_NAME,FORMAT_VERSION,PID,SEQ\n" > $profile_manifest
echo ""","1","file:/${archiveID}/","/${archiveID}/manifest.xml","manifest.xml","METHOD","$STATUS","SIZE","File","xml","","EXTENSION_MISMATCH","${md5_hash}","FORMAT_COUNT","PUID","application/xml","Xml Document","FORMAT_VERSION","${pid}",""" >> $profile_manifest



#-----------------------------------------------------------------------------------------------------------------------
# Produce instruction for the METS
#-----------------------------------------------------------------------------------------------------------------------
instruction_mets=$fileSet/instruction.xml
python ${DIGCOLPROC_HOME}/util/droid_to_instruction.py -s $profile_manifest -t $instruction_mets --objid "$pid" --access "irsh" --submission_date "$datestamp" --autoIngestValidInstruction "$flow_autoIngestValidInstruction" --label "$archiveID $flow_client METS" --action "upsert" --notificationEMail "$flow_notificationEMail" --plan "StagingfileIngestMaster" >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "Failed to create an instruction for the METS."
fi
if [ ! -f $instruction_mets ] ; then
    exit_error "Failed to find an instruction for the METS at $instruction_mets"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Upload the METS file
#-----------------------------------------------------------------------------------------------------------------------
work_instruction_mets=$work/instruction.xml
cp $instruction_mets $work_instruction_mets
ftp_script_base=$work/ftp.$archiveID.$datestamp
ftp_script=$ftp_script_base.mets.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "put -O /${archiveID} ${fileSet}/manifest.xml" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "FTP Failed"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Upload the instruction
#-----------------------------------------------------------------------------------------------------------------------
ftp_script=$ftp_script_base.instruction.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "put -O /${archiveID} ${fileSet}/instruction.xml" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "FTP Failed"
fi


#-----------------------------------------------------------------------------------------------------------------------
# Tell our API we will update this record.
#-----------------------------------------------------------------------------------------------------------------------
wget --no-check-certificate --method=PUT "${api_upload}/${pid}?key=${api_upload_key}"


#-----------------------------------------------------------------------------------------------------------------------
# METS creation finished
#-----------------------------------------------------------------------------------------------------------------------
echo "Finished creation of METS for $pid" >> $log