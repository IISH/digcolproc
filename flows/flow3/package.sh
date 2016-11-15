#!/bin/bash


OBJID="${na}/${archiveID}"
PACKAGE_DIR="${work_base}/package" # a folder to place the archive in.
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"


#-----------------------------------------------------------------------------------------------------------------------
# Here we have our package and can move the working directory to the fileSet.
#-----------------------------------------------------------------------------------------------------------------------
function move_dir {

    if [ -d "$PACKAGE_DIR" ]
    then
        if [ -d "$fileSet" ]
        then
            echo "Rsync fileSet from ${PACKAGE_DIR} to ${fileSet}"
            rsync -av --delete "$PACKAGE_DIR/" "$fileSet"
            rc=$?
            if [[ $rc == 0 ]]
            then
                rm -rf "$PACKAGE_DIR"
            else
                exit_error "$pid" "$TASK_ID" "Error ${rc}. Unable to rsync ${PACKAGE_DIR} to ${fileSet}"
            fi
        fi
    else
        exit_error "$pid" "$TASK_ID" "Expected a working directory ${PACKAGE_DIR} to replace the fileSet ${fileSet}, but it is not there."
    fi

}


function stagingfile {

    file="$1"

    filename=$(basename "$file")
    if [[ "$filename" =~ ^.*\.part([0-9]+)\.rar$ ]]
    then
        seq="${BASH_REMATCH[1]}"
    else
        exit_error "$pid" "$TASK_ID" "Could not extract the sequence number from the file part: ${filename}"
    fi

    location="/${archiveID}/${filename}"
    l="${file}.md5"
    md5sum "$file" > "$l"
    rc=$?
    if [[ $rc != 0 ]]
    then
        exit_error "$pid" "$TASK_ID" "Error ${rc}. Unable to produce a checksum: ${location}"
    fi
    md5=$(cat "$l" | cut -d ' ' -f 1)
    rm "$l"
    pid="${OBJID}.${seq}"

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


#-----------------------------------------------------------------------------------------------------------------------
# We have a valid archive. SHOULD we find a manifest.xml file here, then we will declare it as a master.
#-----------------------------------------------------------------------------------------------------------------------
function manifest {

    file="$1"
    if [ ! -f "$file" ]
    then
        exit_error "$pid" "$TASK_ID" "${file} not found."
    fi

    location="/${archiveID}/manifest.xml"
    l="${file}.md5"
    md5sum "$file" > "$l"
    rc=$?
    if [[ $rc != 0 ]]
    then
        exit_error "$pid" "$TASK_ID" "Error ${rc}. Unable to produce a checksum: ${location}"
    fi
    md5=$(cat "$l" | cut -d ' ' -f 1)
    rm "$l"
    pid="${OBJID}"

    echo "
    <stagingfile>
        <location>${location}</location>
        <md5>${md5}</md5>
        <pid>${pid}</pid>
        <seq>0</seq>
        <contentType>text/xml</contentType>
    </stagingfile>
    "
}



function instruction {
    #-------------------------------------------------------------------------------------------------------------------
    # We have a valid ARCHIVE. Create the SIP.
    #-------------------------------------------------------------------------------------------------------------------
    file_insn="${PACKAGE_DIR}/instruction.xml"
    echo "<instruction
        xmlns='http://objectrepository.org/instruction/1.0/'
        access='$flow_access'
        autoIngestValidInstruction='$flow_autoIngestValidInstruction'
        deleteCompletedInstruction='$flow_deleteCompletedInstruction'
        label='$archiveID $flow_client'
        action='upsert'
        notificationEMail='$flow_notificationEMail'
        plan='StagingfileIngestMaster,StagingfileBindPIDs'
        objid='$OBJID'
        >" > $file_insn

    for file in "$PACKAGE_DIR/"*.rar
    do
        stagingfile "$file" >> "$file_insn"
    done

    manifest "${PACKAGE_DIR}/manifest.xml" >> "$file_insn"

    echo "</instruction>" >> "$file_insn"
}


function pack {
        #---------------------------------------------------------------------------------------------------------------
        # Create a multipart archive.
        #---------------------------------------------------------------------------------------------------------------
        package="${PACKAGE_DIR}/${archiveID}"
        rar a -ep1 -k -m0 -ola -r -rr5% -t -v2147483647b "$package" "$fileSet"  | tee -a $log
        rc=$?
        if [[ $rc != 0 ]] ; then
            rm "$package"
            exit_error "$pid" "$TASK_ID" "rar 'a' command for ${package} for ${fileSet} returned an error ${rc}"
        fi

        #---------------------------------------------------------------------------------------------------------------
        # If we only have one part, Then rename the file accordingly. This way we always have a sequence number.
        #---------------------------------------------------------------------------------------------------------------
        single_archive="${package}.rar"
        if [ -f "$single_archive" ]
        then
            expected_archive="${package}.part01.rar"
            echo "Moving ${single_archive} to ${expected_archive}" >> $log
            mv "$single_archive" "$expected_archive"
        fi


        #---------------------------------------------------------------------------------------------------------------
        # Add the manifest as a separate file.
        #---------------------------------------------------------------------------------------------------------------
        manifest="${fileSet}/manifest.xml"
        cp "$manifest" "$PACKAGE_DIR"
        rc=$?
        if [[ $rc != 0 ]]
        then
            echo "Error ${rc}. Unable to copy manifest for the packaging." >> $log
            exit_error "$pid" "$TASK_ID" "Failed to find an manifest at ${manifest}"
        fi
}



function unpack {
    for package_extension in rar tar tar.gz zip
    do
        for seq in "" ".part1" ".part01" ".part001" ".part0001" ".part00001"
        do
            package="${fileSet}/${archiveID}${seq}.${package_extension}"
            if [ -f "$package" ]
            then
                cmd="a command"
                case "$package_extension" in
                    rar)
                        cmd="unrar x ${package} ${PACKAGE_DIR}"
                    ;;
                    tar)
                        cmd="tar -C ${PACKAGE_DIR} -xvf ${package}"
                    ;;
                    tar.gz)
                        cmd="tar -C ${PACKAGE_DIR} -xvzf ${package}"
                    ;;
                    zip)
                        cmd="unzip ${package} -d ${PACKAGE_DIR}"
                    ;;
                esac

                eval "$cmd" | tee -a $log
                rc=$?
                if [[ $rc == 0 ]]
                then
                    # Keep the original name as a marker for the package.
                    echo -n "$package" > "${work_base}/package.name"
                else
                    exit_error "$pid" "$TASK_ID" "Unable to unpack ${rc}: ${cmd}. Remove all unpacked files first before attempting to make a new backup."
                fi

                #  Below will remove ALL content placed there during the offloading.
                packed_in_folder="${PACKAGE_DIR}/${archiveID}"
                if [ -d "$packed_in_folder" ]
                then
                    # Here we move the main folder straight to the fileset
                    # as it was packed as [ARCHIVEID]/folders and files
                    rsync -av --delete "$packed_in_folder/" "$fileSet" >> $log
                    if [[ $? == 0 ]]
                    then
                        rm -rf "$packed_in_folder"
                    else
                        echo "The rsync gave an error, so I will not remove ${packed_in_folder}." >> $log
                        exit 1
                    fi
                else
                    # Here we move the content that had no main folder to the fileset
                    # as it was packed as just /folders and files
                    rsync -av --delete "${PACKAGE_DIR}/" "$fileSet"
                    if [[ $? == 0 ]]
                    then
                        rm -rf "$PACKAGE_DIR"
                    else
                        echo "The rsync gave an error, so I will not remove ${PACKAGE_DIR}." >> $log
                        exit 1
                    fi
                fi
            fi
        done
    done
}