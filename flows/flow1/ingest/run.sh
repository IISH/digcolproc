#!/bin/bash
#
# /ingest/run.sh
#
# Starts the ingest and objid pid bindings
#
# Usage: run.sh [na] [fileSet] [work directory]

source "${digcolproc_home}setup.sh" $0 "$@"

echo "Start preparing ingest...">>$log
cf=$fileSet/.validate/concordanceValidWithPID.csv
if [ ! -f $cf ] ; then
    echo "Error... did not find $cf">>$log
    echo "Is the dataset validated ?">>$log
    exit -1
fi

md5check=$(md5sum $fileSet/$archiveID.csv)
md5=$(cat $fileSet/.validate/$archiveID.csv.md5)
if [ "$md5" != "$md5check" ] ; then
    echo "The CSV file seems to have been changed after it was validated and must be re-validated first.">>$log
    exit -1
fi

source ./file.sh
source ../pid/run.sh
source ./ead.sh
