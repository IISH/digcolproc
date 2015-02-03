#!/bin/bash

# Iterate over the fileSet and verify a corresponding master with identical pid and checksum over at the Sor.
# When we find a match, remove the file.
# And when all files are gone, remove the fileSet
#
# Usage: run.sh [na] [fileSet] [work directory]

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"

file_instruction=$fileSet/instruction.xml
if [ ! -f "$file_instruction" ] ; then
	echo "Instruction not found: $file_instruction">>$log
	exit 0
fi

report="$log.report"
echo $fileSet > $report
groovy ${DIGCOLPROC_HOME}util/remove.file.groovy -file "$file_instruction" -access_token $flow_access_token -or $or -delete true >> $report
groovy -cp "${DIGCOLPROC_HOME}util/bin/javax.mail-api-1.5.0.jar;${DIGCOLPROC_HOME}util/bin/mail-1.4.7.jar ${DIGCOLPROC_HOME}util/mail.groovy "$report $flow_client "$flow_notificationEMail" "Dagelijkste Sor import van de scans" $mailrelay >> $log

# When all files are processed, the total file count should be one ( the instruction.xml file ).
count=$(find $fileSet -type f \( ! -regex ".*/\..*/..*" \) | wc -l)
if [[ $count == 1 ]] ; then
	history="${fs_parent}/.history"
	mkdir -p $history
	mv $fileSet $history
fi