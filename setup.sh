#!/bin/bash
#
# setup.sh

# Initiate and check our variables.
#
# Usage: setup.sh [calling script: run.sh file] [event]
# E.g.
# setup.sh /usr/bin/digcolproc/flows/flow3/ingest/run.sh /a/b/c/d/flow3/10622/offloader-3/BULK12345/ingest.txt
#
# The fileset is the full path, excluding the event. It consists of:
# /[folders[n]]/[flow name]/[naming authority]/[offloader name]/[archival ID]/



#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}config.sh"



#-----------------------------------------------------------------------------------------------------------------------
# flow_run_folder
# Gets the parent folder of the application run.sh script.
# E.g. /usr/bin/digcolproc/flows/flow3/ingest/
# We enter the command path where we have the run.sh file
#-----------------------------------------------------------------------------------------------------------------------
flow_run_folder=$(dirname $1)
cd "$flow_run_folder"



#-----------------------------------------------------------------------------------------------------------------------
# trigger
# The file whose presence was resppnsible for running the run.sh file
# E.g. /flow3/10622/offloader-3/BULK12345/ingest.txt
#-----------------------------------------------------------------------------------------------------------------------
trigger=$2
rm -f "$trigger"



#-----------------------------------------------------------------------------------------------------------------------
# fileSet
# The fileSet that contains the submission package.
# E.g. /flow3/10622/offloader-3/BULK12345
#-----------------------------------------------------------------------------------------------------------------------
fileSet=$(dirname $trigger)



#-----------------------------------------------------------------------------------------------------------------------
# archiveID
# The name of the folder containing the data.
# E.g. BULK012345
#-----------------------------------------------------------------------------------------------------------------------
archiveID=$(basename $fileSet)



#-----------------------------------------------------------------------------------------------------------------------
# fs_parent
# Gets the parent folder of the fileSet
# E.g. /flow3/10622/offloader-3
#-----------------------------------------------------------------------------------------------------------------------
fs_parent=$(dirname $fileSet)



#-----------------------------------------------------------------------------------------------------------------------
# offloader
# The offloader user name. A linux account.
# E.g. offloader-3
#-----------------------------------------------------------------------------------------------------------------------
offloader=$(basename $fs_parent)



#-----------------------------------------------------------------------------------------------------------------------
# na
# The naming authority
#-----------------------------------------------------------------------------------------------------------------------
fs_parent=$(dirname $fs_parent) # fs_parent is transitional
na=$(basename $fs_parent)



#-----------------------------------------------------------------------------------------------------------------------
# flow
# The flow ( flow1, flow2, etc )
#-----------------------------------------------------------------------------------------------------------------------
fs_parent=$(dirname $fs_parent) # fs_parent is transitional
flow=$(basename $fs_parent)



#-----------------------------------------------------------------------------------------------------------------------
# fs_parent
# Parent folder of the fileSet
# E.g. /a/b/c/d/flow3/10622/offloader-3
#-----------------------------------------------------------------------------------------------------------------------
fs_parent=$(dirname $fileSet)



#-----------------------------------------------------------------------------------------------------------------------
# datestamp
# YYYY-MM-DD current date
#-----------------------------------------------------------------------------------------------------------------------
datestamp=$(date +"%Y-%m-%d")



#-----------------------------------------------------------------------------------------------------------------------
# event
# The action, like 'ingest', 'backup', etc.
#-----------------------------------------------------------------------------------------------------------------------
event=$(basename $flow_run_folder)



#-----------------------------------------------------------------------------------------------------------------------
# work_base
# The base working directory for log and reports
#-----------------------------------------------------------------------------------------------------------------------
work_base=$fs_parent/.work/$archiveID



#-----------------------------------------------------------------------------------------------------------------------
# work
# The working directory for log and reports
#-----------------------------------------------------------------------------------------------------------------------
work=$work_base/$event
mkdir -p $work



#-----------------------------------------------------------------------------------------------------------------------
# log
# The log file
#-----------------------------------------------------------------------------------------------------------------------
time=$(date +"%H")
log="${work}/${datestamp}T${time}.log"
echo "">$log
echo "------------------------------------------------------------------------------------------------------------------------" >> $log
echo "date: $(date)">>$log
echo "datestamp: $datestamp">>$log
echo "trigger: ${trigger}">>$log
echo "DIGCOLPROC_HOME=${DIGCOLPROC_HOME}">>$log
echo "DIGCOLPROC_DEBUG=${DIGCOLPROC_DEBUG}">>$log
echo "offloader: $offloader">>$log
echo "na: $na">>$log
echo "archiveID: $archiveID">>$log
echo "fileSet: $fileSet">>$log
echo "fs_parent: $fs_parent">>$log
echo "flow: $flow">>$log
echo "event: $event">>$log
echo "work: $work">>$log
echo "PATH=${PATH}">>$log
echo "user=$(whoami)">>$log
echo "environment variables:" >>$log
printenv >> $log

#-----------------------------------------------------------------------------------------------------------------------
# Check values
#-----------------------------------------------------------------------------------------------------------------------
if [ -z "$fs_parent" ] ; then
    echo "Parent of the fileset not set.">>$log
    exit -1
fi


if [ ! -d "$fs_parent" ] ; then
    echo "Parent of the fileset not found: ${fs_parent}">>$log
    exit -1
fi

if [[ ! -d "$fileSet" ]] ; then
    echo "Cannot find fileSet ${fileSet} Does the folder or share exist ?">>$log
    exit -1
fi

if [ -z "$event" ] ; then
    echo "event not set.">>$log
    exit -1
fi

if [ -z "$fileSet" ] ; then
    echo "fileSet not set.">>$log
    exit -1
fi

if [ -z "$flow" ] ; then
    echo "flow not set.">>$log
    exit -1
fi

if [ -z "$flow_keys" ] ; then
    echo "flow_keys not set.">>$log
    exit -1
fi



#-----------------------------------------------------------------------------------------------------------------------
# Dynamically assign variables
#-----------------------------------------------------------------------------------------------------------------------
for key in $flow_keys
do
    v=$(eval "echo \$${flow}_${key}")
    k="flow_${key}"
    eval ${k}=$(echo \""${v}"\")
    test=$(eval "echo \${$k}")
    if [ ! -z "$DIGCOLPROC_DEBUG" ]; then
	    echo "${key}=${v}">>$log
	fi
    if [ -z "$test" ] ; then
        echo "Key flow_${key} may not be empty and should be set in config.sh">>$log
        exit -1
    fi
done



#-----------------------------------------------------------------------------------------------------------------------
# Load bash functions
#-----------------------------------------------------------------------------------------------------------------------
for file in "${DIGCOLPROC_HOME}util/functions/*"
do
    if [ -f "$file" ]
    then
        source "$file"
    fi
done