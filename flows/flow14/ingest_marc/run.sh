#!/bin/bash
#
# run.sh
#
# Usage:
# run.sh [na] [folder name]
#
# This script expects a submission package in the folder pattern:
# /a/b/c/10622/offloader/[barcode]
# And with files that start with the barcode:
# /a/b/c/10622/offloader/[barcode]/[barcode].[extension]
# E.g.:
#    /10622/offloader-4/N1234567890



#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh


#-----------------------------------------------------------------------------------------------------------------------
# Is the ingest in progress ?
#-----------------------------------------------------------------------------------------------------------------------
file_instruction=$fileSet/instruction.xml
if [ -f "$file_instruction" ] ; then
    exit_error "Instruction already present: $file_instruction. This may indicate the SIP is staged or the ingest is already in progress. This is not an error."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Now loop though all files in the folder and see if their size is non zero and have a valid syntax.
#-----------------------------------------------------------------------------------------------------------------------
error_number=0
regex_filename="^${archiveID}\.[a-zA-Z0-9]+$|^${archiveID}\.[0-9]+\.[a-zA-Z0-9]+$" # abcdefg.extension  or abcdefg.12345.extension
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
    exit_error "Aborting job because of the previous errors."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Are we in a valid folder ? We expect the barcode to exist in our catalogs.
#-----------------------------------------------------------------------------------------------------------------------
sru_call="${sru}?query=marc.852\$p=\"${archiveID}\"&version=1.1&operation=searchRetrieve&recordSchema=info:srw/schema/1/marcxml-v1.1&maximumRecords=1&startRecord=1&resultSetTTL=0&recordPacking=xml"
access=$(python ${DIGCOLPROC_HOME}/util/sru_call.py --url "$sru_call")
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "The SRU service call produced an error ${sru_call}"
fi
if [ "$access" == "None" ] ; then
    exit_error "No such barcode \"${archiveID}\" found by the SRU service ${sru_call}"
fi
echo "$access" > ${fileSet}/.access.txt



#-----------------------------------------------------------------------------------------------------------------------
# Start the ingest
#-----------------------------------------------------------------------------------------------------------------------
source ../ingest.sh



#-----------------------------------------------------------------------------------------------------------------------
# End job
#-----------------------------------------------------------------------------------------------------------------------
echo "Done. All went well at this side." >> $log
exit 0