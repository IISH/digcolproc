#!/bin/bash

# Iterate over the fileSet and verify a corresponding master with identical pid and checksum over at the Sor.
# When we find a match, remove the file.
# And when all files are gone, remove the fileSet
#
# Usage: run.sh [na] [fileSet] [work directory]

#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh
STATUS=$UPLOADING_TO_PERMANENT_STORAGE
pid=$na/$archiveID



#-----------------------------------------------------------------------------------------------------------------------
# Is there an instruction ?
#-----------------------------------------------------------------------------------------------------------------------
file_instruction=$fileSet/instruction.xml
if [ ! -f "$file_instruction" ] ; then
	echo "Instruction not found: $file_instruction">>$log
	exit 0
fi



#-----------------------------------------------------------------------------------------------------------------------
# Report the status for each file in the instruction.
# This procedure will return a zero exit status if all files are accounted for.
#-----------------------------------------------------------------------------------------------------------------------
report="$log.report_ingest"
echo $fileSet > $report
python ${DIGCOLPROC_HOME}util/report_ingest.py --instruction "$file_instruction" >> $report
rc=$?


#-----------------------------------------------------------------------------------------------------------------------
# Provided there are no errors remove the files.
#-----------------------------------------------------------------------------------------------------------------------
if [[ $rc == 0 ]] ; then
    echo "Remove file files mentioned in the report."
fi


#-----------------------------------------------------------------------------------------------------------------------
# When all files are processed and deleted, the total file count should be one ( the instruction.xml file ). 
#-----------------------------------------------------------------------------------------------------------------------
count=$(find $fileSet -type f \( ! -regex ".*/\..*/..*" \) | wc -l)
if [[ $count == 1 ]] ; then
	history="${fs_parent}/.history"
	mkdir -p $history
	mv $fileSet $history
fi



#-----------------------------------------------------------------------------------------------------------------------
# Notify
#-----------------------------------------------------------------------------------------------------------------------
/usr/bin/sendmail --body "$report" --from "$flow_client" --to "$flow_notificationEMail" --subject "Removal eport for $archiveID" --mail_relay "$mail_relay" --mail_user "$mail_user" --mail_password "$mail_password" >> $log