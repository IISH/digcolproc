#!/bin/bash

# Iterate over the fileSet and verify a corresponding master with identical pid and checksum over at the Sor.
# When we find a match or no match we report it
#
# Usage: run.sh [na] [fileSet] [work directory]

source $FLOWS_HOME/src/main/global/setup.sh $0 "$@"

file_instruction=$fileSet/instruction.xml
if [ ! -f "$file_instruction" ] ; then
	echo "Instruction not found: $file_instruction">>$log
	exit 0
fi

report="$log.report"
echo "When there is no error reported, you can safely remove the folder and it's content: ${fileSet}" > $report
groovy $global_home/remove.file.groovy -file "$file_instruction" -access_token $flow_access_token -or $or -delete false >> $report
groovy -cp "$(cygpath --windows "$HOMEPATH\.m2\repository\javax\mail\javax.mail-api\1.5.0\javax.mail-api-1.5.0.jar");$(cygpath --windows "$HOMEPATH\.m2\repository\javax\mail\mail\1.4.7\mail-1.4.7.jar")" $(cygpath --windows "$global_home/mail.groovy") $(cygpath --windows "$report") $flow_client "$flow_notificationEMail" "Dagelijkste Sor import van de scans" $mailrelay >> $log
