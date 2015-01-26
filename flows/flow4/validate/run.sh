#!/bin/bash
#
# validate.sh
#
# We must be in a datestamp
# See if the identifiers are declared in our metadata catalog.
#

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"

# Are we in a valid directory ?
groovy $(cygpath --windows "${DIGCOLPROC_HOME}util/valid.datestamp.groovy") $fileSet
rc=$?
if [[ $rc != 0 ]] ; then
    echo "There were errors during the validation routine. Invalid foldername. It should be a datestamp, like ${date}" >> $log
    exit -1
fi

groovy $(cygpath --windows "${DIGCOLPROC_HOME}util/validate.sru.groovy") -work $(cygpath --windows "$work") -na $na -fileSet "$fileSet_windows" -sruServer "$sru" -recurse true>>$log
rc=$?
if [[ $rc != 0 ]] ; then
    echo "There were errors during the validation routine." >> $log
    exit -1
fi

# Stop if we find problems
validate_file="$work/validation.txt"
if [ -f $validate_file ] ; then
    count=$(grep -c mislukt $validate_file)
    if [[ $count != 0 ]] ; then
        echo "There where validation issues with ${count} files. Not ingesting." >> $log
        exit -1
    fi
else
    echo "No validation file found at ${validate_file}"
    exit -1
fi