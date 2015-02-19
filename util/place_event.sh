#!/bin/bash
#
# place_event.sh
#
# useage: place_event [event] [optional 'pid']
#
# Iterates over all application folders and starts the startup.sh routine.
# if a pid is given, only folders that contain the pid will be processed.

source "${DIGCOLPROC_HOME}config.sh"
flow=$1
event=$2
pid="$3"

if [ -z "$flow" ] ; then
	echo "No flow given"
	exit -1
fi
if [ -z "$event" ] ; then
	echo "No event given"
	exit -1
fi

key=$flow"_hotfolders"
hotfolders=$(eval "echo \$$key")

for hotfolder in $hotfolders
do
	if [ -d "$hotfolder" ] ; then
        for na in $hotfolder*
        do
            for offloader in $na/* # E.g. offloader1-flow1-acc
            do
                for fileSet in $offloader/*
                do
                    if [ -d $fileSet ] ; then
                        archivalID=$(basename $fileSet)
                        if [[ -z "$pid" ]] || [[ "$archivalID" == "$pid" ]] || [[ -e $fileSet/$fileName ]] ; then
                            echo $(date)>$fileSet/$event
                        fi
                    fi
                done
            done
        done
    fi
done

exit 0