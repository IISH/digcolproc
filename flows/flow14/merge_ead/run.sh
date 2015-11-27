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
# Is the dataset validated?
#-----------------------------------------------------------------------------------------------------------------------
echo "Start preparing merge..." >> $log
cf=$fs_parent/.work/$archiveID/validate/concordanceValid.csv
if [ ! -f $cf ] ; then
    exit_error "Error... did not find $cf Is the dataset validated?"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Start DROID merge for each item
#-----------------------------------------------------------------------------------------------------------------------
while read line
do
    IFS=, read objnr ID <<< "$line"
    (source ./merge_ead_item.sh "$objnr" "$ID")
done < <(python ${DIGCOLPROC_HOME}/util/concordance_to_list.py --concordance "$cf")



#-----------------------------------------------------------------------------------------------------------------------
# End job
#-----------------------------------------------------------------------------------------------------------------------
echo "Done. All went well at this side." >> $log
exit 0