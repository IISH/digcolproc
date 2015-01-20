#!/bin/bash
#
# Test validation for metadata
#
# Usage: ./ead.sh IISH flow home folder

digcolproc_home=$1
if [ ! -d "$digcolproc_home" ] ; then
    echo "digcolproc_home folder should point to the iish-flows home directory."
    exit -1
fi

global_home=$digcolproc_home/src/main/global

na=12345
fileSet=$digcolproc_home/src/test/flow4/$na
work=$fileSet/work
if [ ! -d $work ] ; then
    mkdir $work
fi
log=$work/log.txt

cd $digcolproc_home/src/main/flow4/validate
source ./run.sh