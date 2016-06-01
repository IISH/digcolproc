#!/bin/bash

# Iterate over the fileSet and verify a corresponding master with identical pid and checksum over at the Sor.
# When we find a match or no match we report it
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
echo "When there is no error reported, you can safely remove the folder and it's content: ${fileSet}" > $report
groovy ${DIGCOLPROC_HOME}util/remove.file.groovy -file "$file_instruction" -or $or -delete false >> $report


#-----------------------------------------------------------------------------------------------------------------------
# Notify
#-----------------------------------------------------------------------------------------------------------------------
/usr/bin/sendmail --body "$report" --from "$flow_client" --to "$flow_notificationEMail" --subject "Removal report for $archiveID" --mail_relay "$mail_relay" --mail_user "$mail_user" --mail_password "$mail_password" >> $log



echo "Done..." >> $log
exit 0