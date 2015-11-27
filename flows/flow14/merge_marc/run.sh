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
# Is there a DROID file?
#-----------------------------------------------------------------------------------------------------------------------
profile_extended_csv=$fs_parent/.work/$archiveID/ingest_marc/profile.droid.extended.csv
if [ ! -f "$profile_extended_csv" ] ; then
	exit_error "DROID analysis not found: $profile_extended_csv"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Is there a METS file?
#-----------------------------------------------------------------------------------------------------------------------
mets=$fs_parent/.work/$archiveID/ingest_marc/mets.xml
if [ ! -f "$mets" ] ; then
	exit_error "No original METS document found: $mets"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Start the merge
#-----------------------------------------------------------------------------------------------------------------------
python ${DIGCOLPROC_HOME}/util/mets_to_droid.py --droid $profile_extended_csv --mets $mets >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    exit_error "Failed to perform the merge!"
fi



#-----------------------------------------------------------------------------------------------------------------------
# End job
#-----------------------------------------------------------------------------------------------------------------------
echo "Done. All went well at this side." >> $log
exit 0