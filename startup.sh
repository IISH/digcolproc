#!/bin/bash
#
# startup.sh
#
# Iterates over all application folders and starts the run.sh routine.


source "${DIGCOLPROC_HOME}config.sh"

for flow in ${DIGCOLPROC_HOME}flows/* # Find all potential script folders in /flows/
do
    flow_folder=$(basename $flow)
    for run_folder in $flow/*
    do
        run_script=$run_folder/run.sh # See if there is a /flows/flow[n]/run.sh file
        if [ -f $run_script ] ; then
            key=$flow_folder"_hotfolders"
            hotfolders=$(eval "echo \$$key")
            for hotfolder in $hotfolders # Iterate through all hotfolders where the run.sh can be applied to.
            do
                # The offloader hotfolder convention is:
                # /[one or more directories]/[na]/[offloader account name]/[folder to apply the run.sh to]
                #
                # E.g. hotfolder for flow3 is '/offloader/flow3/'

                # The procedure will find content when it is delivered as:
                # /offloader/flow3/10622/offloader1-flow1-acc/BULK12345

				if [ -d "$hotfolder" ] ; then
                    for na in $hotfolder* # E.g. na=10622
                    do
                        for offloader in $na/* # E.g. offloader1-flow1-acc
                        do
                            for fileSet in $offloader/* #E.g. fileSet=BULK12345
                            do
                                if [ -d "$fileSet" ] ; then
                                    trigger="$fileSet/$(basename $run_folder).txt"
                                    echo $trigger
                                    if [ -f "$trigger" ] ; then
                                        echo "${run_script} \"${trigger}\" \"${fileSet}\"">>/var/log/digcolproc/event.log
                                        $run_script "$trigger">>/var/log/digcolproc/error.log 2>&2 &
                                    fi
                                fi
                            done
                        done
                    done
                fi
            done
        fi
    done
done

exit 0