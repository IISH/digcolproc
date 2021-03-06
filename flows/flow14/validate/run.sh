#!/bin/bash
#
# run.sh
#
# Produce validation

#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh
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
orgOwner=$(stat -c %u $fileSet)
orgGroup=$(stat -c %g $fileSet)
chown -R root:root $fileSet



#-----------------------------------------------------------------------------------------------------------------------
# Produce a droid analysis
#-----------------------------------------------------------------------------------------------------------------------
profile=$work/profile.droid
echo "Begin droid analysis for profile ${profile}" >> $log
droid --recurse -p $profile --profile-resources $fileSet>>$log
rc=$?
if [[ $rc != 0 ]] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "Droid profiling threw an error."
fi
if [[ ! -f $profile ]] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "Unable to find a DROID profile."
fi



#-----------------------------------------------------------------------------------------------------------------------
# produce a report.
#-----------------------------------------------------------------------------------------------------------------------
profile_csv=$work/profile.csv
droid -p $profile --export-file $profile_csv >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "Droid reporting threw an error."
fi
if [ ! -f $profile_csv ] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "Unable to create a droid profile: ${profile_csv}"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Start validation of concordance table based on droid report.
#-----------------------------------------------------------------------------------------------------------------------
python ${DIGCOLPROC_HOME}/util/droid_validate_concordance.py --basepath $fs_parent --droid $profile_csv --concordance $fileSet/$archiveID.csv >> $report
rc=$?
if [[ $rc != 0 ]] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "Validation of the concordance table failed."
fi
cf=$work/concordanceValid.csv
cp $fileSet/$archiveID.csv $cf



#-----------------------------------------------------------------------------------------------------------------------
# Start EAD validation
#-----------------------------------------------------------------------------------------------------------------------
eadFile=$fileSet/$archiveID.xml
if [ ! -f $eadFile ] ; then
    echo "Warning: Unable to find the EAD document at $eadFile" >> $log
else
    archiveIDs=$work/archiveIDs.xml
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><list>" > $archiveIDs
    while read line
    do
        IFS=, read objnr ID <<< "$line"
        echo "<item>$ID</item>" >> $archiveIDs
    done < <(python ${DIGCOLPROC_HOME}/util/concordance_to_list.py --concordance "$cf")
    echo "</list>" >> $archiveIDs

    eadReport=$work/ead.report.html
    groovy ${DIGCOLPROC_HOME}util/ead.groovy "$eadFile" "$archiveIDs" $eadReport >> $log
    if [ -f $eadReport ] ; then
        echo "See the EAD validation for inventarisnummer and unitid matches at" >> $log
        echo $eadReport >> $log
    else
        chown -R "$orgOwner:$orgGroup" $fileSet
        exit_error "Unable to validate $eadFile"
    fi
fi



#-----------------------------------------------------------------------------------------------------------------------
# End validation
#-----------------------------------------------------------------------------------------------------------------------
chown -R "$orgOwner:$orgGroup" $fileSet

echo "You can savely ignore warnings about Thumbs.db" >> $report
echo $(date)>>$log
echo "Done validate.">>$log

body="/tmp/report.txt"
echo "Rapportage op $report">$body
/usr/bin/sendmail --body "$body" --from "$flow_client" --to "$flow_notificationEMail" --subject "Flow 14 validation" --mail_relay "$mail_relay" --mail_user "$mail_user" --mail_password "$mail_password" >> $log
rm $body

exit $?
