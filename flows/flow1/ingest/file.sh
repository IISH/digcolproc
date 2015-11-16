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

# Upload the files
ftp_script=$work/$archiveID.txt
${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "synchronize remote -mirror -criteria=size $fileSet_windows\Tiff $archiveID/Tiff" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit -1
fi

# Upload the derivatives
${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "synchronize remote -mirror -criteria=size $fileSet_windows\jpeg $archiveID/.level1" "$flow_ftp_connection" "$log"
${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "synchronize remote -mirror -criteria=size $fileSet_windows\.level2 $archiveID/.level2" "$flow_ftp_connection" "$log"
${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "synchronize remote -mirror -criteria=size $fileSet_windows\.level3 $archiveID/.level3" "$flow_ftp_connection" "$log"
${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "synchronize remote -mirror -criteria=size $fileSet_windows\.level4 $archiveID/.level4" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit -1
fi

echo "Create instruction for our files with arguments: groovy">>$log
echo $(cygpath --windows "${DIGCOLPROC_HOME}util/instruction.csv.groovy") -fileSet $(cygpath --windows "$fileSet") -csv $(cygpath --windows "$cf") -label "$archiveID $flow_client" -action add -contentType image/tiff -autoIngestValidInstruction $flow_autoIngestValidInstruction -notificationEMail $flow_notificationEMail  -plan "StagingfileIngestLevel3,StagingfileIngestLevel2,StagingfileIngestLevel1,StagingfileBindPIDs,StagingfileIngestMaster">>$log
groovy $(cygpath --windows "${DIGCOLPROC_HOME}util/instruction.csv.groovy") -fileSet $(cygpath --windows "$fileSet") -csv $(cygpath --windows "$cf") -label "$archiveID $flow_client" -action add -contentType image/tiff -autoIngestValidInstruction $flow_autoIngestValidInstruction -notificationEMail $flow_notificationEMail  -plan "StagingfileIngestLevel3,StagingfileIngestLevel2,StagingfileIngestLevel1,StagingfileBindPIDs,StagingfileIngestMaster">>$log
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
${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "put $fileSet_windows\instruction.xml $archiveID/instruction.xml" "$flow_ftp_connection" "$log"
rc=$?
mv $fileSet/.level1 $fileSet/Jpeg
rm $ftp_script
if [[ $rc != 0 ]] ; then
    exit -1
fi

echo $(date)>>$log
echo "Done files update.">>$log