#!/bin/bash

# run.sh
#
# Usage:
# run.sh [na] [folder name]
#
# This script expects a submission package in the folder pattern:
# /a/b/c/10622/offloader/YYY-MM-DD]

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"


# Is the ingest in progress ?
file_instruction=$fileSet/instruction.xml
if [ -f "$file_instruction" ] ; then
	echo "Instruction already present: $file_instruction">>$log
	echo "This may indicate the SIP is staged or the ingest is already in progress. This is not an error.">>$log
	exit 0
fi


# Are we in a valid folder ? We expect 20YY-MM-DD
regex_datestamp="20[0-9]{2}-[0-1][0-9]-[0-3][0-9]$"
if [[ $archiveID =~ $regex_datestamp ]]
then
    echo "ok"
else
    echo "Invalid datestamp for the folder name. Expect ${regex_datestamp} but got ${archiveID}" >> $log
    exit -1
fi


# Now loop though all files in the folder and see if there size is non zero and have a valid syntax.
error_number=0
regex_filename="^[a-zA-Z0-9]+\.[a-zA-Z0-9]+$|^[a-zA-Z0-9]+\.[0-9]+\.[a-zA-Z0-9]+$" # abcdefg.extension  or abcdefg.12345.extension
for f in $(find "$fileSet" -type f )
do
    filesize=$(stat -c%s "$f")
    if [[ $filesize == 0 ]]
    then
        let "error_number++"
        echo "Error ${error_number}: File is zero bytes: ${f}" >> $log
    fi
    f=$(basename $f)
    if [[ ! $f =~ $regex_filename ]]
    then
        let "error_number++"
        echo "Error ${error_number}: File is ${f} but expect ${regex_filename}" >> $log
    fi
done
if [[ $error_number == 0 ]]
then
    echo "Files look good" >> $log
else
    exit -1
fi


# Lock the folder and it's contents
chown -R root:root $fileSet


# Upload the files
ftp_script_base=$work/ftp.$archiveID.$datestamp
ftp_script=$ftp_script_base.files.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "mirror --reverse --verbose ${fileSet} /${archiveID}" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit $rc
fi


# Produce instruction
groovy "${DIGCOLPROC_HOME}util/instruction.groovy" -na $na -fileSet "$fileSet" -access $flow_access -sruServer $sru -tag 542 -code m -autoIngestValidInstruction "$flow_autoIngestValidInstruction" -label "$archiveID $flow_client" -action upsert -notificationEMail "$flow_notificationEMail" -recurse true -use_objd_seq_pid_from_file true>>$log
rc=$?
if [[ $rc != 0 ]] ; then
    echo "Problem when creating the instruction.">>$log
    exit $rc
fi

# Upload the instruction
ftp_script=$ftp_script_base.instruction.txt
bash ${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "put -O /${archiveID} ${fileSet}/instruction.xml" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit $rc
fi

echo "Done. All went well at this side." >> $log

exit 0