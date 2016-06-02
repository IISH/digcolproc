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


file_instruction=$fileSet/instruction.xml
if [ ! -f "$file_instruction" ] ; then
	echo "Instruction not found: $file_instruction">>$log
	exit 0
fi

report="$log.report"
echo $fileSet > $report
groovy ${DIGCOLPROC_HOME}util/remove.file.groovy -file "$file_instruction" -access_token $flow_access_token -or $or -delete true >> $report

#-----------------------------------------------------------------------------------------------------------------------
# Notify
#-----------------------------------------------------------------------------------------------------------------------
echo "Sent mail to" >> $log
/usr/bin/sendmail --body "$report" --from "$flow_client" --to "$flow_notificationEMail" --subject "Removal report for $archiveID" --mail_relay "$mail_relay" --mail_user "$mail_user" --mail_password "$mail_password" >> $log



# When all files are processed, the total file count should be one ( the instruction.xml file ).
count=$(find $fileSet -type f \( ! -regex ".*/\..*/..*" \) | wc -l)
if [[ $count == 1 ]] ; then
	history="$(dirname $fileSet)/.history"
	mkdir -p $history
	mv $fileSet $history
fi