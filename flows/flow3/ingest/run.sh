#!/bin/bash

# run.sh
#
# Collects all folders under the fileSet.
# For each folder creates a manifest and UDF image
#
# Example:
# /a/b/BULK23456/1/files and folders
# /a/b/BULK23456/2/files and folders
#
# Will produce:
# /a/b/BULK23456/.level2/BULK23456.1.csv
# /a/b/BULK23456/BULK23456.1.iso
# /a/b/BULK23456/.level2/BULK23456.2.csv
# /a/b/BULK23456/BULK23456.2.iso
# /a/b/BULK23456/instruction.xml
#
# Usage:
# file.sh [na] [folder name] [log]

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"

GiB=$(echo "(2^30)" | bc)
BlockLimit=128
ftp_script_base=$work/ftp.$archiveID.$datestamp

ok=true
for d in $fileSet/*
do
    size=$(du $d -s | cut -d '/' -f 1)
    blocks=$(echo "$size / $GiB" | bc)
    if [[ $blocks -gt $BlockLimit ]] ; then
        echo "The folder $d with size $size is larger then the allowed size of $GiB x $BlockLimit">>$log
	    ok=false
    fi
done
if [ $ok == false ] ; then
    exit -1
fi

echo "Start a droid analysis">>$log
p=$(pwd)
for d in $fileSet/*
do
    if [ -d $d ] ; then
		mkdir -p "$fileSet/.level2"
		subfolder=$(basename $d)
        profile=$(cygpath --windows "$d/profile.droid")
        manifest="$fileSet/.level2/$archiveID.$subfolder.csv"
		cd $(cygpath $DROID_HOME)
        droid.bat -p "$profile" -a $(cygpath --windows "$d") -R>>$log
        droid.bat -p "$profile" -e "$(cygpath --windows "$manifest")">>$log
		rm "$d/profile.droid"
        cd "$p"
		groovy removePath.groovy "$manifest" $(cygpath --windows "$d")
		cp "$manifest" $d/
    fi
done

echo "Create the UDF 1.02 images">>$log
for d in $fileSet/*
do
    if [ -d $d ] ; then
        subfolder=$(basename $d)
		source=$(cygpath --windows "$d")
		target=$(cygpath --windows "$fileSet/$archiveID.$subfolder.iso")
        # See Oscdimg Command-Line Options at technet.microsoft.com/en-us/library/cc749036(v=ws.10).aspx
		oscdimg.exe -udfver102 -u2 -l$archiveID.$subfolder -h -w4 $source $target>>$log
        rc=$?
        if [[ $rc != 0 ]] ; then
            echo "There were errors when creating the image for $d">>$log
            exit -1
        fi
    fi
done

# Upload the files
ftp_script=$ftp_script_base.files.txt
${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "synchronize remote -mirror -criteria=size -filemask=\"*.iso|/\" $fileSet_windows $archiveID" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit -1
fi
${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "synchronize remote -mirror -criteria=size $fileSet_windows\\.level1 $archiveID/.level1" "$flow_ftp_connection" "$log"
if [[ $rc != 0 ]] ; then
    exit -1
fi
${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "synchronize remote -mirror -criteria=size $fileSet_windows\\.level2 $archiveID/.level2" "$flow_ftp_connection" "$log"
if [[ $rc != 0 ]] ; then
    exit -1
fi
${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "synchronize remote -mirror -criteria=size $fileSet_windows\\.level3 $archiveID/.level3" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit -1
fi

# Produce instruction and upload it
groovy $(cygpath --windows "${DIGCOLPROC_HOME}util/instruction.groovy") -na $na -fileSet "$fileSet_windows" -autoIngestValidInstruction $flow_autoIngestValidInstruction -label "$datestamp UDF image $archiveID $flow_client" -notificationEMail $flow_notificationEMail -plan "StagingfileIngestLevel3,StagingfileIngestLevel2,StagingfileIngestLevel1,StagingfileBindPIDs,StagingfileIngestMaster">>$log
ftp_script=$ftp_script_base.instruction.txt
${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "put $fileSet_windows\instruction.xml $archiveID/instruction.xml" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit -1
fi

exit 0