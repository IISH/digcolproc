#!/bin/bash
#
# Test custom level2 creation
#
# Usage: ./ead.sh IISH flow home folder

digcolproc_home=$1
if [ ! -d "$digcolproc_home" ] ; then
    echo "digcolproc_home folder should point to the iish-flows home directory."
    exit -1
fi

global_home=$digcolproc_home/src/main/global

cd $digcolproc_home/src/main/flow1/custom_level2
na=12345

for fileSet in $digcolproc_home/src/test/flow1/$na/*
do
    archiveID=$(basename $fileSet)
    work=$fileSet/work
    if [ ! -d $work ] ; then
        mkdir $work
    fi
    log=$work/log.txt

    # There ought to be some images in the test .level1 folder
    targetLevel=level2
    source ./run.sh
done