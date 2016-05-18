#!/bin/bash

# Iterate over the fileSet and verify a corresponding master with identical pid and checksum over at the Sor.
# When we find a match, remove the file.
# And when all files are gone, remove the fileSet
#
# Usage: run.sh [na] [fileSet] [work directory]

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"



#-----------------------------------------------------------------------------------------------------------------------
# Is there an instruction ?
#-----------------------------------------------------------------------------------------------------------------------
file_instruction=$fileSet/instruction.xml
if [ ! -f "$file_instruction" ] ; then
	echo "Instruction not found: $file_instruction">>$log
	exit 0
fi


#-----------------------------------------------------------------------------------------------------------------------
# Create a csv of the PIDs we want to check out.
#-----------------------------------------------------------------------------------------------------------------------
file_pids_table="${work}/pids_table.csv"
python ${DIGCOLPROC_HOME}/util/xslt_transformer.py --xml_file="$file_instruction" --xsl_file="create_pids_table.xsl" --result_file="$file_pids_table" >> $log 2>&1
rc=$?
if [[ $rc != 0 ]] ; then
    echo "xslt_transformer.py threw an error ${rc}">>$log
    exit 1
fi
if [ ! -f $file_concordancetable ]
then
    echo "Unable to create ${file_pids_table}">>$log
    exit 1
fi



#-----------------------------------------------------------------------------------------------------------------------
# For each pid and md5, do a check.
#-----------------------------------------------------------------------------------------------------------------------
while read line
do
    IFS=, read pid md5 <<< "$line"
        url="${or}/metadata/${pid}"
        file_or="${work}/${md5}.txt"
        wget --header "accept: application/xml" -O "$file_or" "$url"
        md5_in_or=$(python ${DIGCOLPROC_HOME}/util/xslt_transformer.py --xml_file="$file_or" --xsl_file="md5_in_or.xsl")

done < $file_pids_table



#-----------------------------------------------------------------------------------------------------------------------
# Start the removal procedure
#-----------------------------------------------------------------------------------------------------------------------
source ../remove.sh