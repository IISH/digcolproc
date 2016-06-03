#!/bin/bash

# run.sh
#
# Usage:
# run.sh [na] [folder name]


#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"


ftp_script_base=$work/ftp.$archiveID.$datestamp
file_instruction=$fileSet/instruction.xml
if [ -f "$file_instruction" ] ; then
	echo "Instruction already present: $file_instruction">>$log
	exit 0
fi

rm $work/done.txt

# Harvest and create a list of updates. We harvest everything from the last 5 days.
from=$(groovy -e "def format = 'yyyy-MM-dd' ; def date = Date.parse(format, '$datestamp').minus(5) ; print(date.format(format))")
file_access=$work/access.txt
groovy ${DIGCOLPROC_HOME}util/oai2harvester.groovy -na $na -baseURL $oai -verb ListRecords -set $flow5_set -from $from -metadataPrefix marcxml > $file_access

# create instruction header:
echo "Creating instruction from ${file_access}" >> $log
count=0
rm $file_instruction
echo "<instruction xmlns='http://objectrepository.org/instruction/1.0/' access='$flow_access' autoIngestValidInstruction='$flow_autoIngestValidInstruction' label='$archiveID $flow_client' action='upsert' notificationEMail='$flow_notificationEMail' plan='StagingfileIngestMaster'>" > $file_instruction
while read line
do
    if [[ "$line" == \#* ]] ; then
        echo $line >> $log
    else
        IFS=, read id access pid <<< "$line"
        count=$((count + 1))
        echo "<stagingfile><pid>${pid}</pid><access>${access}</access><embargo>null</embargo><embargoAccess>null</embargoAccess><contentType>null</contentType><objid>null</objid><seq>0</seq><label>null</label></stagingfile>" >> $file_instruction
    fi
done < $file_access
echo "</instruction>" >> $file_instruction

if [[ $count == 0 ]] ; then
    rm $file_instruction
    echo "Nothing to upload as the count was zero." >> $log
	touch $work/done.txt
    exit 0
fi

# Upload the instruction
echo "Upload remaining instruction...">>$log
ftp_script=$work/instruction.ftp
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "mirror --reverse --delete --verbose ${fileSet} /${archiveID}" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "FTP error with uploading the object repository instruction." $rc
fi


touch $work/done.txt
echo "Done..." >> $log
exit 0