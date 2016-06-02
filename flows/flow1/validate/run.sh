#!/bin/bash
#
# startup.sh
#
# Produce validation
# Add Instruction
# Prepare a mets document


#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"

report=$work/report.txt

echo "Start validation">>$log
echo "Validation for $archiveID" > $report
echo "Started on $(date)">>$report
md5sum $fileSet/$archiveID.csv > $work/$archiveID.csv.md5
java -Xms512m -Xmx512m -cp /opt/validation/validation-1.0.jar org.objectrepository.validation.ConcordanceMain -fileSet $fileSet >> $report
cf=$work/concordanceValidWithPID.csv
mv $fileSet/concordanceValidWithPID.csv $cf
if [ ! -f $cf ] ; then
    echo "Unable to find $cf">>$log
	echo "The validation was interrupted.">>$log
	exit -1
fi

echo "You can savely ignore warnings about Thumbs.db" >> $report
echo $(date)>>$log
echo "Done validate.">>$log


#-----------------------------------------------------------------------------------------------------------------------
# Notify
#-----------------------------------------------------------------------------------------------------------------------
body="/tmp/report.txt"
echo "Rapportage op $report">$body
/usr/bin/sendmail --body "$report" --from "$flow_client" --to "$flow_notificationEMail" --subject "Removal report for $archiveID" --mail_relay "$mail_relay" --mail_user "$mail_user" --mail_password "$mail_password" >> $log

echo "Done..." >> $log
exit 0
