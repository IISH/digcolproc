#!/bin/bash
#
# ingest.files.sh
#
# Will iterate over the desired folder; take all sub folders; and for each kick start the creation of an instruction.

source $FLOWS_HOME/config.sh

# Enable share
net use $FLOW2_SHARE
if [ ! -d $flow2_share_path ] ; then
	echo "Cannot connect to share $FLOW2_HOME"
	exit -1
fi

for d in $flow2_share_path/*
do
    for fileSet in $d/*
    do
    	na=$(basename $d)
    	$FLOWS_HOME/src/main/flow2/ingest.file.sh $na $fileSet
    done
done


exit 0
