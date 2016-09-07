#!/bin/bash


PACKAGE_DIR="${work_base}/${archiveID}" # a folder to place the archive in..
WORKDIR_RAR="${PACKAGE_DIR}/package/.rar" # a folder to place some temp files.
ARCHIVE="${PACKAGE_DIR}/${archiveID}.rar"


#-----------------------------------------------------------------------------------------------------------------------
# Here we have our package and can move the working directory to the fileSet.
#-----------------------------------------------------------------------------------------------------------------------
function move_dir {

    if [ -d "$PACKAGE_DIR" ]
    then
        if [ -d "$fileSet" ]
        then
            echo "Removing fileSet: ${fileSet}"
            rm -rf "$fileSet"
        fi
        echo "Move working directory ${PACKAGE_DIR} to fileSet ${fileSet}"
        mv "$PACKAGE_DIR" "$fileSet"
    else
        echo "Expected a working directory ${PACKAGE_DIR} to replace the fileSet ${fileSet}, but it is not there."
        exit 1
    fi

}


function stagingfile {

    file="$1"

    filename=$(basename "$file")
    if [[ "$filename" =~ ^.*\.part([0-9]+)\.rar$ ]]
    then
        seq="${BASH_REMATCH[1]}"
    else
        echo "Could not extract the sequence number from the file part: ${filename}"
        exit 1
    fi

    location="/${archiveID}/${filename}"
    l="${file}.md5"
    md5sum "$file" > "$l"
    md5=$(cat "$l" | cut -d ' ' -f 1)
    rm "$l"
    pid="${objid}.${seq}"

    echo "
    <stagingfile>
      <location>${location}</location>
      <md5>${md5}</md5>
      <pid>${pid}</pid>
      <seq>${seq}</seq>
      <contentType>application/x-rar-compressed</contentType>
    </stagingfile>
    "
}


function instruction {
    #-------------------------------------------------------------------------------------------------------------------
    # We have a valid ARCHIVE. Create the SIP.
    #-------------------------------------------------------------------------------------------------------------------
    file_instruction="${PACKAGE_DIR}/instruction.xml"
    echo "<instruction
        xmlns='http://objectrepository.org/instruction/1.0/'
        access='$flow_access'
        autoIngestValidInstruction='$flow_autoIngestValidInstruction'
        deleteCompletedInstruction='$flow_deleteCompletedInstruction'
        label='$archiveID $flow_client'
        action='upsert'
        notificationEMail='$flow_notificationEMail'
        plan='StagingfileIngestMaster,StagingfileBindPIDs'
        objid='$pid'
        >" > $file_instruction

    for file in "$workdir/"*.rar
    do
        stagingfile "$file" >> "$file_instruction"
    done

    manifest="${fileSet}/manifest.xml"
    if [ -f "$manifest" ]
    then
        target="${PACKAGE_DIR}/manifest.xml"
        cp "${manifest}" "$target"
        manifest "$manifest" >> "$file_instruction"
    fi

    echo "</instruction>" >> "$file_instruction"
}


function package {
        #---------------------------------------------------------------------------------------------------------------
        # Create a multipart ARCHIVE.
        #---------------------------------------------------------------------------------------------------------------
        rm -rf "$PACKAGE_DIR"
        rm -rf "$WORKDIR_RAR"
        mkdir "$PACKAGE_DIR"
        mkdir "$WORKDIR_RAR"
        rar a -ep1 -k -m0 -ola -r -rr5% -t -v2147483647b -w"$WORKDIR_RAR" "$archive" "$fileSet"  | tee -a $log
        rc=$?
        rm -rf "$WORKDIR_RAR"
        if [[ $rc != 0 ]] ; then
            echo "rar 'a' command on ${ARCHIVE} ${fileSet} returned an error ${rc}"
            rm -rf "$workdir"
            exit $rc
        fi

        #---------------------------------------------------------------------------------------------------------------
        # If we only have one part, Then rename the file accordingly. This way we always have a sequence number.
        #---------------------------------------------------------------------------------------------------------------
        if [ -f "$archive" ]
        then
            expected_archive="${ARCHIVE}.part01.rar"
            echo "Moving ${ARCHIVE} to ${expected_archive}"
            mv "$archive" "$expected_archive"
        fi
}