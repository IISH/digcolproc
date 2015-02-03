#!/bin/bash
#
# setup.sh

# Initiate and check our variables.
#
# Usage: setup.sh [calling script: run.sh file] [event] [fileSet]

source "${DIGCOLPROC_HOME}config.sh"

echo "\$1 = $1"
echo "\$2 = $2"
echo "\$3 = $3"
flow_run_folder=$(dirname $1)	 # Gets the parent folder of the application script
trigger=$2                       # Trigger file, E.g. /flow3/10622/offloader-3/BULK12345/.work/ingest.txt
fileSet=$3                       # The fileSet, E.g. /flow3/10622/offloader-3/BULK12345
archiveID=$(basename $fileSet)   # E.g. BULK012345
fs_parent=$(dirname $fileSet)	 # Gets the parent folder, E.g. /flow3/10622/offloader-3
offloader=$(basename $fs_parent) # The offloader name, E.g. offloader-3
fs_parent=$(dirname $fs_parent)	 # Gets the parent folder, E.g. /flow3/10622/
na=$(basename $fs_parent)        # Now proceeds to the naming authority
fs_parent=$(dirname $fs_parent)	 # Gets the parent folder, E.g. /flow3
flow=$(basename $fs_parent)      # The flow ( flow1, flow2, etc )
fs_parent=$(dirname $fileSet)    # Parent folder of the fileSet
datestamp=$(date +"%Y-%m-%d")    # YYYY-MM-DD current date


cd "$flow_run_folder"		            # Make where we have the run.sh file the current directory
event=$(basename $flow_run_folder)	    # Now proceeds to the actual command
work=$fs_parent/.work/$archiveID/$event # The Working directory for logging and reports
mkdir -p $work

if [ -z "$fs_parent" ] ; then
    echo "Parent of the fileset not set."
    exit -1
fi

if [ ! -d "$fs_parent" ] ; then
    echo "Parent of the fileset not found: ${fs_parent}"
    exit -1
fi

if [ -z "$event" ] ; then
    echo "event not set."
    exit -1
fi

if [ -z "$fileSet" ] ; then
    echo "fileSet not set."
    exit -1
fi

if [ -z "$flow" ] ; then
    echo "flow not set."
    exit -1
fi

if [ -z "$flow_keys" ] ; then
    echo "flow_keys not set."
    exit -1
fi

mkdir -p $work
rm -f "$trigger"

log=$work/$datestamp.log
echo "log: ${log}">$log
echo "trigger: ${trigger}">>$log
echo "date: $(date)">>$log
echo "datestamp: $datestamp">>$log
echo "offloader: $offloader">>$log
echo "na: $na">>$log
echo "archiveID: $archiveID">>$log
echo "fileSet: $fileSet">>$log
echo "fs_parent: $fs_parent">>$log
echo "flow: $flow">>$log
echo "event: $event">>$log
echo "work: $work">>$log

# Assign values
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

if [[ ! -d "$fileSet" ]] ; then
    echo "Cannot find fileSet $fileSet">>$log
    echo "Does the folder or share exist ?">>$log
    exit -1
fi