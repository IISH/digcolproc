#!/bin/bash
#
# ingest.sh



#-----------------------------------------------------------------------------------------------------------------------
# Determine PID
#-----------------------------------------------------------------------------------------------------------------------
pid=$na/$archiveID



#-----------------------------------------------------------------------------------------------------------------------
# Lock the folder and it's contents
#-----------------------------------------------------------------------------------------------------------------------
chown -R root:root $fileSet



#-----------------------------------------------------------------------------------------------------------------------
# Produce a droid analysis
#-----------------------------------------------------------------------------------------------------------------------
profile=$work/profile.droid
echo "Begin droid analysis for profile ${profile}" >> $log
droid --recurse -p $profile --profile-resources $fileSet>>$log
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "Droid profiling threw an error."
fi
if [[ ! -f $profile ]] ; then
    exit_error "Unable to find a DROID profile."
fi



#-----------------------------------------------------------------------------------------------------------------------
# produce a report.
#-----------------------------------------------------------------------------------------------------------------------
profile_csv=$profile.csv
droid -p $profile --export-file $profile_csv >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "Droid reporting threw an error."
fi
if [ ! -f $profile_csv ] ; then
    exit_error "Unable to create a droid profile: ${profile_csv}"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Now extend the report with two columns: a md5 checksum and a persistent identifier
#-----------------------------------------------------------------------------------------------------------------------
profile_extended_csv=$profile.extended.csv
python ${DIGCOLPROC_HOME}/util/droid_extend_csv.py --sourcefile $profile_csv --targetfile $profile_extended_csv --na $na --fileset $fileSet --force_seq >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "Failed to extend the droid report with a PID and md5 checksum."
fi
if [[ ! -f $profile_extended_csv ]] ; then
    exit_error "Unable to make a DROID report."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Produce instruction from the report.
#-----------------------------------------------------------------------------------------------------------------------
work_instruction=$work/instruction.xml
python ${DIGCOLPROC_HOME}/util/droid_to_instruction.py -s $profile_extended_csv -t $work_instruction --objid "$pid" --access "$access" --submission_date "$datestamp" --autoIngestValidInstruction "$flow_autoIngestValidInstruction" --label "$archiveID $flow_client" --action "add" --use_seq --notificationEMail "$flow_notificationEMail" --plan "StagingfileIngestLevel3,StagingfileIngestLevel2,StagingfileIngestLevel1,StagingfileBindPIDs,StagingfileBindObjId,StagingfileIngestMaster" >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "Failed to create an instruction."
fi
if [ ! -f $work_instruction ] ; then
    exit_error "Failed to find an instruction at ${work_instruction}"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Upload the files
#-----------------------------------------------------------------------------------------------------------------------
ftp_script_base=$work/ftp.$archiveID.$datestamp
ftp_script=$ftp_script_base.files.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "mirror --reverse --delete --verbose ${fileSet} /${archiveID}" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "FTP Failed"
    exit 1
fi



#-----------------------------------------------------------------------------------------------------------------------
# Upload the instruction
#-----------------------------------------------------------------------------------------------------------------------
mv $work_instruction $file_instruction
ftp_script=$ftp_script_base.instruction.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "put -O /${archiveID} ${fileSet}/instruction.xml" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "FTP Failed"
    exit 1
fi