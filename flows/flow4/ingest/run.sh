#!/bin/bash
#
# run.sh
#
# Usage:
# run.sh [na] [folder name]
#
# This script expects a submission package in the folder pattern:
# /a/b/c/10622/offloader/[barcode]
# And with files that start with the barcode:
# /a/b/c/10622/offloader/[barcode]/[barcode].[extension]
# E.g.:
#    /10622/offloader-4/N1234567890



#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh



#-----------------------------------------------------------------------------------------------------------------------
# Is the ingest in progress ?
#-----------------------------------------------------------------------------------------------------------------------
file_instruction=$fileSet/instruction.xml
if [ -f "$file_instruction" ] ; then
    exit_error "Instruction already present: $file_instruction. This may indicate the SIP is staged or the ingest is already in progress. This is not an error."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Now loop though all files in the folder and see if their size is non zero and have a valid syntax.
#-----------------------------------------------------------------------------------------------------------------------
error_number=0
regex_filename="^${archiveID}\.[a-zA-Z0-9]+$|^${archiveID}\.[0-9]+\.[a-zA-Z0-9]+$" # abcdefg.extension  or abcdefg.12345.extension
for f in $(find "$fileSet" -type f )
do
    filesize=$(stat -c%s "$f")
    if [[ $filesize == 0 ]]
    then
        let "error_number++"
        echo "Error ${error_number}: File is zero bytes: ${f}" >> $log
    fi
    f=$(basename $f)
    if [[ ! $f =~ $regex_filename ]]
    then
        let "error_number++"
        echo "Error ${error_number}: File is ${f} but expect ${regex_filename}" >> $log
    fi
done
if [[ $error_number == 0 ]]
then
    echo "Files look good" >> $log
else
    exit_error "Aborting job because of the previous errors."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Are we in a valid folder ? We expect the barcode to exist in our catalogs.
#-----------------------------------------------------------------------------------------------------------------------
sru_call="${sru}?query=marc.852\$p=\"${archiveID}\"&version=1.1&operation=searchRetrieve&recordSchema=info:srw/schema/1/marcxml-v1.1&maximumRecords=1&startRecord=1&resultSetTTL=0&recordPacking=xml"
access=$(python ${DIGCOLPROC_HOME}/util/sru_call.py --url "$sru_call")
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "The SRU service call produced an error ${sru_call}"
fi
if [ "$access" == "None" ] ; then
    exit_error "No such barcode \"${archiveID}\" found by the SRU service ${sru_call}"
fi



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
    exit_error "$pid" ${STATUS} "Droid reporting threw an error."
fi
if [ ! -f $profile_csv ] ; then
    exit_error "$pid" ${STATUS} "Unable to create a droid profile: ${profile_csv}"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Now extend the report with two columns: a md5 checksum and a persistent identifier
#-----------------------------------------------------------------------------------------------------------------------
profile_extended_csv=$profile.extended.csv
python ${DIGCOLPROC_HOME}/util/droid_extend_csv.py --sourcefile $profile_csv --targetfile $profile_extended_csv --na $na --fileset $fileSet >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "Failed to extend the droid report with a PID and md5 checksum."
fi
if [[ ! -f $profile_extended_csv ]] ; then
    exit_error "Unable to make a DROID report."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Create a mets document
#-----------------------------------------------------------------------------------------------------------------------
manifest=${fileSet}/manifest.xml
python ${DIGCOLPROC_HOME}/util/droid_to_mets.py --sourcefile $profile_extended_csv --targetfile $manifest --objid "$pid"
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "Failed to create a mets document."
fi
if [ ! -f $manifest ] ; then
    exit_error "Failed to find a mets file at ${manifest}"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Add the mets file to the manifest.csv, in order for it to be in the xml instruction
#-----------------------------------------------------------------------------------------------------------------------
md5_hash=$(md5sum $manifest | cut -d ' ' -f 1)
echo ""","1","file:/${archiveID}/","/${archiveID}/manifest.xml","manifest.xml","METHOD","$STATUS","SIZE","File","xml","","EXTENSION_MISMATCH","${md5_hash}","FORMAT_COUNT","PUID","application/xml","Xml Document","FORMAT_VERSION","${pid}",""">>$profile_extended_csv



#-----------------------------------------------------------------------------------------------------------------------
# Produce instruction from the report.
#-----------------------------------------------------------------------------------------------------------------------
pid=$na/$archiveID
work_instruction=$work/instruction.xml
python ${DIGCOLPROC_HOME}/util/droid_to_instruction.py -s $profile_extended_csv -t $work_instruction --objid "$pid" --access "$access" --submission_date "$datestamp" --autoIngestValidInstruction "$flow_autoIngestValidInstruction" --label "$archiveID $flow_client" --action "add" --use_seq --notificationEMail "$flow_notificationEMail" --plan "StagingfileBindPIDs,StagingfileIngestMaster" >> $log
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



#-----------------------------------------------------------------------------------------------------------------------
# End job
#-----------------------------------------------------------------------------------------------------------------------
echo "Done. All went well at this side." >> $log
exit 0