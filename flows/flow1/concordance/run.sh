#!/bin/bash
#
# /concordance/run.sh
#
# Reconstructs a concordance CSV
#
# Usage: run.sh [na] [fileSet] [work directory]

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"

echo "Start creating a concordance table...">>$log
file_concordance=$fileSet/$archiveID.csv
if [ -f $file_concordance ] ; then
    echo "There is already a file called ${file_concordance}" >> $log
    echo "Skipping...." >> $log
    exit 1
fi

python folder2concordance.py --fileset $fileSet --target $file_concordance
