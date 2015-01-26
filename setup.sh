#!/bin/bash
#
# setup.sh

# Initiate and check our variables.
#
# Usage: setup.sh [full path of the scripts that called this file] [the fileSet without a trailing slash] [the flow]

source "${DIGCOLPROC_HOME}config.sh"

echo "\$0 = $0"
echo "\$1 = $1"
echo "\$2 = $2"
echo "\$3 = $3"
echo "\$4 = $4"
event=$(dirname $1)			    # Gets the parent folder of the application script
echo "\$event = $event"
fileSet=$2                      # The fileSet
flow=$3                         # The flow ( flow1, flow2, etc )
echo "dirname \$fileSet = dirname $fileSet"
fs_parent=$(dirname $fileSet)	# Gets the parent folder
echo "\$fs_parent = $fs_parent"

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
datestamp=$(date +"%Y-%m-%d")
log=$work/$datestamp.log
echo "log: ${log}"
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