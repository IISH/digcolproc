#!/bin/bash
#
# run.sh
#
# Iterates over all application folders and starts the startup.sh routine.

config=/etc/digcolproc/config.sh
if [ -f $config ] ; then
    source $config
else
    echo "Cannot find the configuration file at ${config}"
    exit -1
fi

for flow in "${digcolproc_home}flows/*"
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
                    for na in $hotfolder/*
                    do
                        for fileSet in $na/*
                        do
                            if [ -d "$fileSet" ] ; then
                                echo $fileSet
                                event="$fileSet/$(basename $run_folder).txt"
                                if [ -f "$event" ] ; then
                                    echo "$event">>/tmp/event.txt
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