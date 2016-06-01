#!/bin/bash
#
# run.sh
# Verify if the access status was set accordingly.
#
# Usage:
# run.sh [na] [folder name]

source $FLOWS_HOME/src/main/global/setup.sh $0 "$@"

report=$work/report.txt
file_access=$fileSet/.ingest/access.txt
if [ ! -f $file_access ] ; then
	echo "${file_access} not found. Nothing to do." >> $log
	exit 0
fi

file_done=$fileSet/.ingest/done.txt
if [ ! -f $file_done ] ; then
	echo "${file_done} not found. Nothing to do." >> $log
	exit 0
fi

echo $fileSet > $report
successfull=0
ignored=0
failed=0

while read line
do
    if [[ "$line" == \#* ]] ; then
        echo $line
    else
        IFS=, read id access pid <<< "$line"
        currentStatus=$(groovy currentOrStatus.groovy "${or}/metadata/${pid}?accept=text/xml&format=xml")
        if [[ "$currentStatus" == "$access" ]] ; then
            successfull=$((successfull + 1))
			echo "Success: ${line}" >> $report
        else
            if [[ "$currentStatus" == "404" ]] ; then
				ignored=$((ignored + 1))
                echo "Ignore: ${currentStatus} ${line}" >> $report
            else
                failed=$((failed + 1))
                echo "Fail: got '${currentStatus}' but expect '${access}' ${line}" >> $report
            fi
        fi
    fi
done < $file_access

echo "----------------------------------------------------------------------" >> $report
echo "Successfull: ${successfull}" >> $report
echo "Ignored: ${ignored}" >> $report
echo "Failed: ${failed}" >> $report

groovy -cp "$(cygpath --windows "$HOMEPATH\.m2\repository\javax\mail\javax.mail-api\1.5.0\javax.mail-api-1.5.0.jar");$(cygpath --windows "$HOMEPATH\.m2\repository\javax\mail\mail\1.4.7\mail-1.4.7.jar")" $(cygpath --windows "$global_home/mail.groovy") $(cygpath --windows "$report") $flow_client "$flow_notificationEMail" "Dagelijkste Sor access status updates." $mailrelay >> $log

if [[ $failed == 0 ]] ; then
    history="$(dirname $fileSet)/.history"
    mkdir -p $history
    mv $fileSet $history
else
    echo "There were ${count} failures" >> $report
fi
