#!/bin/bash
#
# run.sh
#
# Treat the entire content as individual SIPs
#
# For each child folder found in this folder, move the child folder a level higher and remember the list.
# Trigger this with bulk.txt which must contain


source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"


for folder in "${fileSet}"/*
do
    if [ -d "$folder" ]
    then
        rsync -av "$folder" "$fs_parent"
        if [[ $? != 0 ]]
        then
            echo "rsync failed from ${fs_parent} to ${fs_parent}." >> $log
            exit 1
        fi

        # Now add the command
        to="${fs_parent}/$(basename $folder)"
        touch "${to}/${trigger_content}"
    fi
done


echo "I think we are done for today." >> $log