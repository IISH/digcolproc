#!/bin/bash
#
# remove.sh



#-----------------------------------------------------------------------------------------------------------------------
# Start removal procedure
#-----------------------------------------------------------------------------------------------------------------------
echo "Started removal procedure $pid" >> $log



#-----------------------------------------------------------------------------------------------------------------------
# TODO: Has the SOR processed the complete instruction?
#-----------------------------------------------------------------------------------------------------------------------
#echo "Waiting for instruction to be completely processed by the SOR." >> $log
#while true
#do
#    sor_status_code=$(curl -o /dev/null --silent --head --write-out '%{http_code}' "$or/instruction/$pid?access_token=$flow_access_token")
#    if [[ sor_status_code -eq 404 ]] ; then
#        sleep 300
#    elif [[ sor_status_code -ne 200 ]] ; then
#        exit_error "The SOR returned an unexpected status code $sor_status_code."
#    else
#        break
#    fi
#done



#-----------------------------------------------------------------------------------------------------------------------
# Removal procedure. Use -delete true to remove a file when it is confirmed that is exists in the object repository
#-----------------------------------------------------------------------------------------------------------------------
report="$log.report"
echo $fileSet > $report
file_instruction=$fileSet/instruction.xml
instruction_mets=$fileSet/instruction_mets.xml
groovy ${DIGCOLPROC_HOME}util/remove.file.groovy -file "$file_instruction" -access_token $flow_access_token -or $or -delete true >> $report
groovy ${DIGCOLPROC_HOME}util/remove.file.groovy -file "$instruction_mets" -access_token $flow_access_token -or $or -delete true >> $report
# TODO: Delete true or false? Difference in flow 1 and flow 4.



#-----------------------------------------------------------------------------------------------------------------------
# When all files are processed and deleted, the total file count should be 2 (instruction.xml , instruction_mets.xml).
#-----------------------------------------------------------------------------------------------------------------------
count=$(find $fileSet -type f \( ! -regex ".*/\..*/..*" \) | wc -l)
if [[ $count == 2 ]] ; then
	history="${fs_parent}/.history"
	mkdir -p $history
	mv $fileSet $history
fi



#-----------------------------------------------------------------------------------------------------------------------
# Notify
#-----------------------------------------------------------------------------------------------------------------------
/usr/bin/sendmail --body "$report" --from "$flow_client" --to "$flow_notificationEMail" --subject "Removal eport for $archiveID" --mail_relay "$mail_relay" --mail_user "$mail_user" --mail_password "$mail_password" >> $log



#-----------------------------------------------------------------------------------------------------------------------
# Removal procedure finished
#-----------------------------------------------------------------------------------------------------------------------
echo "Finished removal procedure for $pid" >> $log