#!/bin/bash

# run.sh
#
# Usage:
# run.sh [na] [folder name]

# TODO: enable the config line
#source "${digcolproc_home}config.sh" $0 "$@"

ftp_script_base=$work/ftp.$archiveID.$datestamp

file_instruction=$fileSet/instruction.xml
if [ -f "$file_instruction" ] ; then
	echo "Instruction already present: $file_instruction">>$log
	exit 0
fi

# Upload the files
ftp_script=$ftp_script_base.files.txt
$global_home/ftp.sh "$ftp_script" "synchronize remote -mirror -filemask=\"|.*/\" $fileSet_windows $archiveID" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit -1
fi

# Produce instruction
groovy $(cygpath --windows "$global_home/instruction.groovy") -na $na -fileSet "$fileSet_windows" -access $flow_access -sruServer $sru -tag 542 -code m -autoIngestValidInstruction $flow_autoIngestValidInstruction -label "$archiveID $flow_client" -action upsert -notificationEMail $flow_notificationEMail -recurse true>>$log
rc=$?
if [[ $rc != 0 ]] ; then
    echo "Problem when creating the instruction.">>$log
    exit -1
fi

# Upload the instruction
ftp_script=$ftp_script_base.instruction.txt
$global_home/ftp.sh "$ftp_script" "put $fileSet_windows\instruction.xml $archiveID/instruction.xml" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit -1
fi

exit 0
