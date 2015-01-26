#!/bin/bash
#
# Test validation for metadata
#
# Usage: ./run.sh [IISH flow home folder]

digcolproc_home=$1
flow=flow5

if [ ! -d "$digcolproc_home" ] ; then
    echo "digcolproc_home folder should point to the iish-flows home directory."
    exit -1
fi
digcolproc_home=$digcolproc_home

global_home=$digcolproc_home/src/main/global
if [ ! -d "${DIGCOLPROC_HOME}util" ] ; then
    echo "global_home folder should point to: ${DIGCOLPROC_HOME}util"
    exit -1
fi

test_folder=$digcolproc_home/src/main/$flow/ingest
if [ ! -d "$test_folder" ] ; then
    echo "test_folder folder should point to: $test_folder"
    exit -1
fi

na=12345
runFrom=$digcolproc_home/src/test/$flow
fileSet=$runFrom/$na
work=$fileSet/work
if [ ! -d $work ] ; then
    mkdir -p $work
fi
log=$work/log.txt

cd $digcolproc_home/src/main/$flow/ingest
source ./run.sh $runFrom $fileSet $flow