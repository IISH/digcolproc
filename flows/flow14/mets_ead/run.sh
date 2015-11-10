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
# Start METS creation for each item
#-----------------------------------------------------------------------------------------------------------------------
cf=$fs_parent/.work/$archiveID/validate/concordanceValid.csv
while read line
do
    IFS=, read objnr ID <<< "$line"
    (source ./mets_ead_item.sh "$objnr" "$ID")
done < <(python ${DIGCOLPROC_HOME}/util/concordance_to_list.py --concordance "$cf")



#-----------------------------------------------------------------------------------------------------------------------
# End job
#-----------------------------------------------------------------------------------------------------------------------
echo "Done. All went well at this side." >> $log
exit 0