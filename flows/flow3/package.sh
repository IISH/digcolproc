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
            if [[ $rc != 0 ]]
            then
                echo "Error ${rc}. Unable to rsync ${PACKAGE_DIR} to ${fileSet}" >> $log
                exit $rc
            fi
        fi
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
    rc=$?
    if [[ $rc != 0 ]]
    then
        echo "Error ${rc}. Unable to produce a checksum: ${location}" >> $log
        exit $rc
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
        echo "${file} not found."
        exit 1
    fi

    location="/${archiveID}/manifest.xml"
    l="${file}.md5"
    md5sum "$file" > "$l"
    rc=$?
    if [[ $rc != 0 ]]
    then
        echo "Error ${rc}. Unable to produce a checksum: ${location}" >> $log
        exit $rc
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
        objid='$OBJID'
        >" > $file_instruction

    for file in "$PACKAGE_DIR/"*.rar
    do
        stagingfile "$file" >> "$file_instruction"
    done

    manifest "${PACKAGE_DIR}/manifest.xml" >> "$file_instruction"

    echo "</instruction>" >> "$file_instruction"
}


function pack {
        #---------------------------------------------------------------------------------------------------------------
        # Create a multipart archive.
        #---------------------------------------------------------------------------------------------------------------
        package="${PACKAGE_DIR}/${archiveID}"
        rar a -ep1 -k -m0 -ola -r -rr5% -t -v2147483647b "$package" "$fileSet"  | tee -a $log
        rc=$?
        if [[ $rc != 0 ]] ; then
            echo "rar 'a' command for ${package} for ${fileSet} returned an error ${rc}" >> $log
            rm "$package"
            exit $rc
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
            exit $rc
        fi
}



function unpack {
    for package_extension in rar tar tar.gz zip
    do
        package="${fileSet}/${archiveID}.${package_extension}"
        if [ -f "$package" ]
        then
            number_of_files=$(ls "$fileSet" | wc -l)
            if [[ $number_of_files != 1 ]]
            then
                echo "Found ${number_of_files} files, but only expect a single one: ${package}"
                exit 1
            fi

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
                echo "Unable to unpack ${rc}: ${cmd}" >> $log
                echo "Remove all unpacked files first before attempting to make a new backup." >> $log
                exit 1
            fi

            packed_in_folder="${PACKAGE_DIR}/${archiveID}"
            if [ -d "$packed_in_folder" ]
            then
                # Here we move the main folder straight to the fileset
                # as it was packed as [ARCHIVEID]/folders and files
                rsync -av --delete "$packed_in_folder/" "$fileSet" >> $log
            else
                # Here we move the content that had no main gfolder to the fileset
                # as it was packed as folders and files
                rsync -av --delete "${PACKAGE_DIR}/" "$fileSet"
            fi
        fi
    done
}