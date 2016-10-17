#!/bin/bash
#
# place_event.sh
#
# usage: place_event [event] [optional 'filename']
#
# Iterates over all application folders and places an event in the fileSets.
# If a archivalID was set, it will create a fileSet and placed the event in that.

#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}config.sh" $0 "$@"
flow=$1
event=$2
archivalID=$3

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
	if [ -d "$hotfolder" ]
	then
        for na in $hotfolder/*
        do
            for offloader in $na/*
            do
                if [ -d $offloader ]
                then
                    if [ -z "$archivalID" ]
                    then
                        for fileset in $offloader/*
                        do
                            if [ -d $fileset ]
                            then
                                echo $(date)>"${fileset}/${event}"
                            fi
                        done
                    else
                        fileset="${offloader}/${archivalID}"
                        mkdir -p "$fileset"
                        echo $(date)>"${fileset}/${event}"
                    fi
                fi
            done
        done
    fi
done

exit 0