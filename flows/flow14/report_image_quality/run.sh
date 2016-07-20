#!/bin/bash
#
# run.sh
#
# Usage:
# run.sh [na] [folder name]
#
# Description:
# Make a report based on a supplied CSV table: report-data-csv
# The csv must be of the form: "TCN Value","Call Number Label","Barcode"
# The report will create a new CSV with an extra column, containing the content information about the file.
#
# Jira: https://jira.socialhistoryservices.org/browse/DIGCOLPROC-485



#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"


#-----------------------------------------------------------------------------------------------------------------------
# Create the report
#-----------------------------------------------------------------------------------------------------------------------
file="${fileSet}/report-data.csv"
if [ -f "$file" ]
then
    echo "File not found: ${file}"
    exit 1
else
    python report_image_quality.py --file "$file" --na "$na" --url "${or}" >> $log
fi


rc=$?
if [[ $rc == 0 ]]
then
    echo "I think we are done for today..."
    exit 0
else
    echo "The procedure threw an error code ${rc}"
    exit 1
fi