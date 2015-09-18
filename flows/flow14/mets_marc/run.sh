#!/bin/bash
#
# run.sh
#
# Usage:
# run.sh [na] [folder name]
#

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh



#-----------------------------------------------------------------------------------------------------------------------
# Is there an instruction ?
#-----------------------------------------------------------------------------------------------------------------------
file_instruction=$fileSet/instruction.xml
if [ ! -f "$file_instruction" ] ; then
	exit_error "Instruction not found: $file_instruction"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Is there an access file ?
#-----------------------------------------------------------------------------------------------------------------------
access_file=$fileSet/.access.txt
if [ ! -f "$access_file" ] ; then
	exit_error "Access file not found: $access_file"
fi
access=$(<"$access_file")



#-----------------------------------------------------------------------------------------------------------------------
# Start the mets creation
#-----------------------------------------------------------------------------------------------------------------------
profile_extended_csv=$fs_parent/.work/$archiveID/ingest_marc/profile.droid.extended.csv
pid=$na/$archiveID
source ../mets.sh



#-----------------------------------------------------------------------------------------------------------------------
# End job
#-----------------------------------------------------------------------------------------------------------------------
echo "Done. All went well at this side." >> $log
exit 0