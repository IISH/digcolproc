#!/bin/bash
#
# setup.sh

# Initiate and check our variables.
#
# Usage: setup.sh [full path of the scripts that called this file] [the fileSet without a trailing slash] [the flow]

event=$(dirname $1)			    # Gets the parent folder of the application script
fileSet=$2                      # The fileSet
flow=$3                         # The flow ( flow1, flow2, etc )
fs_parent=$(dirname $fileSet)	# Gets the parent folder
na=$(basename $fs_parent)		# Now proceeds to the naming authority
cd "$event"					    # Make it the current directory
event=$(basename $event)	    # Now proceeds to the actual command
work=$fileSet/.$event		    # The Working directory for logging and reports

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
rm -f "$fileSet/$event.txt"

archiveID=$(basename $fileSet)
fileSet_windows=$(cygpath --windows $fileSet)
log=$work/$datestamp.log
echo "date: $(date)">$log
echo "na: $na">>$log
echo "fileSet: $fileSet">>$log
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
	echo "${key}=${v}">>$log
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