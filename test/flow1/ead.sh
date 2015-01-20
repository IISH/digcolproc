#!/bin/bash
#
# Test report EAD and concordance relationship
#
# Usage: ./ead.sh IISH flow home folder

digcolproc_home=$1
if [ ! -d "$digcolproc_home" ] ; then
    echo "digcolproc_home folder should point to the iish-flows home directory."
    exit -1
fi
digcolproc_home=$digcolproc_home

global_home=$digcolproc_home/src/main/global

cd $digcolproc_home/src/main/flow1/validate
fileSet=$digcolproc_home/src/test/flow1
work=$fileSet/work
if [ ! -d $work ] ; then
    mkdir $work
fi
log=$work/log.txt
archiveID=ARCH12345
cf=$fileSet/cf.txt

source ./ead.sh

cd $digcolproc_home/src/main/flow1/ingest
source ./ead.sh