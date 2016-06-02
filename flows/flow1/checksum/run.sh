#!/bin/bash

# /checksum/run.sh
#
# Compares the checksums
#
# Usage: run.sh [na] [fileSet] [work directory]


#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"


#-----------------------------------------------------------------------------------------------------------------------
# Remove DOS \r
#-----------------------------------------------------------------------------------------------------------------------
file=$fileSet/checksum.md5
if [ ! -f $file ] ; then
    echo "File not found: $file">$report
    echo "No checksum file found at $file">$log
    exit -1
fi
backup=$fileSet/.checksum.md5
if [ ! -f $backup ] ; then
    cp $file $backup
fi
tr -d '\r' < $file > /$work/$archiveID
mv /$work/$archiveID $file


#-----------------------------------------------------------------------------------------------------------------------
# Check the md5
#-----------------------------------------------------------------------------------------------------------------------
report=$work/$archiveID.report.txt
md5sum --check $file > $report


echo "Done." >> $log

exit 0