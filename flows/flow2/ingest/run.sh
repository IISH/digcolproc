#!/bin/bash

# run.sh
#
# Usage:
# run.sh [na] [folder name]


#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"


ftp_script_base=$work/ftp.$archiveID.$datestamp
file_instruction=$fileSet/instruction.xml
if [ -f "$file_instruction" ] ; then
	echo "Instruction already present: $file_instruction">>$log
	exit 0
fi

# Upload the files
ftp_script=$work.files.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "mirror --reverse --verbose ${fileSet} ${archiveID}" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "$pid" $STAGINGAREA "FTP error with uploading the Tiff files."
fi

# Produce instruction
groovy ${DIGCOLPROC_HOME}util/instruction.groovy -na $na -fileSet "$fileSet" -access $flow_access -sruServer $sru -tag 542 -code m -autoIngestValidInstruction $flow_autoIngestValidInstruction -label "$archiveID $flow_client" -action upsert -notificationEMail $flow_notificationEMail -recurse true>>$log
rc=$?
if [[ $rc != 0 ]] ; then
    echo "Problem when creating the instruction.">>$log
    exit -1
fi

# Upload the instruction
echo "Upload remaining instruction...">>$log
file_instruction=$fileSet/instruction.xml
ftp_script=$work/instruction.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "put -O /${archiveID} ${file_instruction}" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "$pid" $STAGINGAREA "FTP error with uploading the object repository instruction."
fi

exit 0
