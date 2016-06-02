#!/bin/bash
#
# /ingest/file.sh
#
# Upload files
# Add Instruction
#

find $fileSet -type f -name "Thumbs.db" -exec rm -f {} \;
find $fileSet -type f -name "Thumbs.db.md5" -exec rm -f {} \;

echo "Upload files...">>$log

if [[ ! -d $fileSet/Tiff ]] ; then
	echo "Expecting the folder $fileSet/Tiff"
	echo "Stopping procedure."
	exit -1
fi


#-----------------------------------------------------------------------------------------------------------------------
# Now start the reverse mirror for the master Tiff
#-----------------------------------------------------------------------------------------------------------------------
ftp_script_base=${work}/ftp.$archiveID.$datestamp
ftp_script=${ftp_script_base}.files.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "mirror --reverse --verbose ${fileSet}/Tiff /${archiveID}/Tiff" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "FTP error with uploading the Tiff files." $rc
fi


#-----------------------------------------------------------------------------------------------------------------------
# Now start the reverse mirror for the jpegs. The jpeg folder correspondents with .level1
#-----------------------------------------------------------------------------------------------------------------------
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "mirror --reverse --verbose ${fileSet}/.level1 /${archiveID}/Jpeg" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "FTP error with uploading the Tiff files." $rc
fi


#-----------------------------------------------------------------------------------------------------------------------
# Now start the reverse mirror for the other levels
#-----------------------------------------------------------------------------------------------------------------------
for bucket in .level2 .level3 .level4
do
    bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "mirror --reverse --verbose ${fileSet}/${bucket} /${archiveID}/${bucket}" "$flow_ftp_connection" "$log"
    rc=$?
    if [[ $rc != 0 ]] ; then
        exit_error "FTP error with uploading the Tiff files." $rc
    fi
done


echo "Create instruction for our files with arguments: groovy">>$log
groovy "${DIGCOLPROC_HOME}util/instruction.csv.groovy" -fileSet "$fileSet" -csv "$cf" -label "$archiveID $flow_client" -access open -action add -contentType image/tiff -autoIngestValidInstruction $flow_autoIngestValidInstruction -notificationEMail $flow_notificationEMail  -plan "StagingfileIngestLevel3,StagingfileIngestLevel2,StagingfileIngestLevel1,StagingfileBindPIDs,StagingfileIngestMaster">>$log
rc=$?
if [[ $rc != 0 ]] ; then
	echo "Problem when creating the instruction.">>$log
    exit -1
fi
if [ ! -f $fileSet/instruction.xml ] ; then
    echo "Instruction not found.">>$log
    exit -1
fi


echo "Upload remaining instruction...">>$log
file_instruction=$fileSet/instruction.xml
ftp_script=$work/instruction.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "put -O /${archiveID} ${file_instruction}" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "FTP error with uploading the object repository instruction." $rc
fi


rm $ftp_script

echo $(date)>>$log
echo "Done files update.">>$log