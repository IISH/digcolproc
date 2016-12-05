#!/bin/bash
#
# run.sh
#
# Treat the entire content as individual SIPs
#
# For each child folder found in this folder, move the child folder a level higher and remember the list.
# Trigger this with bulk.txt which must contain


source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"

if [ -z "$trigger_content" ]
then
    echo "Error: expected an event in bulk.txt" >> $log
    exit 1
fi

filename="${trigger_content%.*}"
available="${flow_base}/${filename}"
if [ ! -d "$available" ]
then
    echo "Error: ${trigger_content} is not a valid event." >> $log
    exit 1
fi



org_owner=$(stat -c %u $fileSet)
org_group=$(stat -c %g $fileSet)

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

        chown -R $org_owner:$org_group "$to"
    fi
done


echo "I think we are done for today." >> $log

exit 0