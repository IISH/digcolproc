#!/bin/bash
#
# run.sh
#
# Iterates over all application folders and starts the startup.sh routine.

source "${DIGCOLPROC_HOME}config.sh"

for flow in ${DIGCOLPROC_HOME}flows/*
do
    flow_folder=$(basename $flow)
    for run_folder in $flow/*
    do
        run_script=$run_folder/run.sh
        if [ -f $run_script ] ; then
            key=$flow_folder"_hotfolders"
            hotfolders=$(eval "echo \$$key")
            for hotfolder in $hotfolders
            do
				if [ -d "$hotfolder" ] ; then
                    for na in $hotfolder*
                    do
                        for fileSet in $na/*
                        do
                            if [ -d "$fileSet" ] ; then
                                event="$fileSet/$(basename $run_folder).txt"
                                if [ -f "$event" ] ; then
                                    echo "$event > ${run_script} ${fileSet} ${flow_folder}">>/tmp/event.txt
                                    $run_script "$fileSet" "$flow_folder" &
                                fi
                            fi
                        done
                    done
                fi
            done
        fi
    done
done

exit 0