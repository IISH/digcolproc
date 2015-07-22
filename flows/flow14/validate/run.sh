#!/bin/bash
#
# run.sh
#
# Produce validation

#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"

report=$work/report.txt



#-----------------------------------------------------------------------------------------------------------------------
# Start validation
#-----------------------------------------------------------------------------------------------------------------------
echo "Start validation">>$log
echo "Validation for $archiveID" > $report
echo "Started on $(date)">>$report
md5sum $fileSet/$archiveID.csv > $work/$archiveID.csv.md5



#-----------------------------------------------------------------------------------------------------------------------
# Lock the folder and it's contents
#-----------------------------------------------------------------------------------------------------------------------
chown -R root:root $fileSet



#-----------------------------------------------------------------------------------------------------------------------
# Produce a droid analysis
#-----------------------------------------------------------------------------------------------------------------------
profile=$work/profile.droid
echo "Begin droid analysis for profile ${profile}" >> $log
droid --recurse -p $profile --profile-resources $fileSet>>$log
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "Droid profiling threw an error."
fi
if [[ ! -f $profile ]] ; then
    exit_error "Unable to find a DROID profile."
fi



#-----------------------------------------------------------------------------------------------------------------------
# produce a report.
#-----------------------------------------------------------------------------------------------------------------------
profile_csv=$work/profile.csv
droid -p $profile --export-file $profile_csv >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "Droid reporting threw an error."
fi
if [ ! -f $profile_csv ] ; then
    exit_error "Unable to create a droid profile: ${profile_csv}"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Start validation of concordance table based on droid report.
#-----------------------------------------------------------------------------------------------------------------------
python ${DIGCOLPROC_HOME}/util/droid_validate_concordance.py --basepath $fs_parent --droid $profile_csv --concordance $fileSet/$archiveID.csv >> $report
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "Validation of the concordance table failed."
fi
cf=$work/concordanceValid.csv
cp $fileSet/$archiveID.csv $cf



#-----------------------------------------------------------------------------------------------------------------------
# Start EAD validation TODO: Move to ingest?
#-----------------------------------------------------------------------------------------------------------------------
source ./ead.sh



#-----------------------------------------------------------------------------------------------------------------------
# End validation
#-----------------------------------------------------------------------------------------------------------------------
echo "You can savely ignore warnings about Thumbs.db" >> $report
echo $(date)>>$log
echo "Done validate.">>$log

body="/tmp/report.txt"
echo "Rapportage op $report">$body
groovy -cp "$(cygpath --windows "$HOMEPATH\.m2\repository\javax\mail\javax.mail-api\1.5.0\javax.mail-api-1.5.0.jar");$(cygpath --windows "$HOMEPATH\.m2\repository\javax\mail\mail\1.4.7\mail-1.4.7.jar")" $(cygpath --windows "${DIGCOLPROC_HOME}util/mail.groovy") $(cygpath --windows "$body") $flow_client "$flow_notificationEMail" "flow1 validation" $mailrelay >>$log
rm $body

exit $?
