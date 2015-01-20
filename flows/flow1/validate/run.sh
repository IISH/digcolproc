#!/bin/bash
#
# startup.sh
#
# Produce validation
# Add Instruction
# Prepare a mets document

source "${digcolproc_home}setup.sh" $0 "$@"

report=$work/report.txt

echo "Start validation">>$log
echo "Validation for $archiveID" > $report
echo "Started on $(date)">>$report
md5sum $fileSet/$archiveID.csv > $work/$archiveID.csv.md5
java -Xms512m -Xmx512m -cp $(cygpath --windows "$HOMEPATH\.m2\repository\org\objectrepository\validation\1.0\validation-1.0.jar") org.objectrepository.validation.ConcordanceMain -fileSet $(cygpath --windows "$fileSet") >> $report
cf=$work/concordanceValidWithPID.csv
mv $fileSet/concordanceValidWithPID.csv $cf
if [ ! -f $cf ] ; then
    echo "Unable to find $cf">>$log
	echo "The validation was interrupted.">>$log
	exit -1
fi

source ./ead.sh

echo "You can savely ignore warnings about Thumbs.db" >> $report
echo $(date)>>$log
echo "Done validate.">>$log

body="/tmp/report.txt"
echo "Rapportage op $report">$body
groovy -cp "$(cygpath --windows "$HOMEPATH\.m2\repository\javax\mail\javax.mail-api\1.5.0\javax.mail-api-1.5.0.jar");$(cygpath --windows "$HOMEPATH\.m2\repository\javax\mail\mail\1.4.7\mail-1.4.7.jar")" $(cygpath --windows "$global_home/mail.groovy") $(cygpath --windows "$body") $flow_client "$flow_notificationEMail" "flow1 validation" $mailrelay >>$log
rm $body

exit $?
