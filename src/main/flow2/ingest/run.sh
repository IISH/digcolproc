#!/bin/bash

# run.sh
#
# Usage:
# run.sh [na] [folder name]

source $FLOWS_HOME/src/main/global/setup.sh $0 "$@"

ftp_script_base=$work/ftp.$archiveID.$datestamp

file_instruction=$fileSet/instruction.xml
if [ -f "$file_instruction" ] ; then
	echo "Instruction already present: $file_instruction">>$log
	exit 0
fi


# Upload the files
ftp_script=$ftp_script_base.files.txt
$global_home/ftp.sh "$ftp_script" "synchronize remote -mirror -filemask=\"|.*/\" $fileSet_windows $archiveID" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit -1
fi

# Produce instruction and upload the filee
groovy $(cygpath --windows "$global_home/instruction.groovy") -na $na -fileSet "$fileSet_windows" -autoIngestValidInstruction $flow_autoIngestValidInstruction -label "$archiveID $flow_client" -action upsert -notificationEMail $flow_notificationEMail -recurse true>>$log
rc=$?
if [[ $rc != 0 ]] ; then
    echo "Problem when creating the instruction.">>$log
    exit -1
fi


ftp_script=$ftp_script_base.instruction.txt
$global_home/ftp.sh "$ftp_script" "put $fileSet_windows\instruction.xml $archiveID/instruction.xml" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit -1
fi

exit 0
