#!/bin/bash


#-----------------------------------------------------------------------------------------------------------------------
# Check the target folder is empty.
#-----------------------------------------------------------------------------------------------------------------------
count=$(ls "$fileSet" | wc -l)
if [[ $count != 0 ]]
then
    exit_error "$pid" $TASK_ID "The folder ${fileSet} must be empty but found ${count} files."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Get the METS document that declares each file in the package.
#-----------------------------------------------------------------------------------------------------------------------
manifest_file="$work/manifest.xml"
manifest_url="${or}/mets/${pid}"
wget -O "$manifest_file" --header="Authorization: bearer ${flow_access_token}" --no-check-certificate "$manifest_url"
rc=$?
if [[ $rc != 0 ]] || [ ! -f "$manifest_file" ]
then
    exit_error "$pid" $TASK_ID "Unable to download a file ${manifest_url}"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Get each file mentioned in the manifest.
#-----------------------------------------------------------------------------------------------------------------------
url_from_manifest="${work}/url_from_manifest.txt"
python ${DIGCOLPROC_HOME}/util/xslt_transformer.py --xml_file="$manifest_file" --xsl_file="url_from_manifest.xsl" > "$url_from_manifest"
rc=$?
if [[ $rc != 0 ]]
then
     exit_error "$pid" $TASK_ID "Unable to make a list of files that are in the manifest ${manifest_file}"
fi



#-----------------------------------------------------------------------------------------------------------------------
# For each file in the manifest, download it in the fileset.
#-----------------------------------------------------------------------------------------------------------------------
while read line
do
    IFS=" " read id filename <<< "$line"
    url="${or}/file/master/${id}"
    file="${fileSet}/${filename}"
    wget -S -O "$file" --header="Authorization: bearer ${flow_access_token}" --no-check-certificate "$url" >> $log
    rc=$?
    if [[ $rc != 0 ]] || [ ! -f "$file" ]
    then
        rm "$file"
        exit_error "$pid" $TASK_ID "Unable to download a file ${file}"
    fi
done < "$url_from_manifest"



#-----------------------------------------------------------------------------------------------------------------------
# Extract the package.
#-----------------------------------------------------------------------------------------------------------------------
source ../package.sh
unpack



#-----------------------------------------------------------------------------------------------------------------------
# Release the folder and it's contents
#-----------------------------------------------------------------------------------------------------------------------
chown -R $offloader:$na $fileSet



#-----------------------------------------------------------------------------------------------------------------------
# Make a list of all the files using the manifest.xml document that was in the package
#-----------------------------------------------------------------------------------------------------------------------
manifest_file="${fileSet}/manifest.xml"
manifest_file_csv="$work/manifest.csv"
python download_mets_content.py --file "$manifest_file" > "$manifest_file_csv"
rc=$?
if [[ $rc != 0 ]]
then
    exit_error "$pid" $TASK_ID "Error ${rc}: unable to run download_mets_content.sh"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Now verify each file that is in the list. Does it exist and does the checksum match.
#-----------------------------------------------------------------------------------------------------------------------
python validate_package.py --fs_parent "$fs_parent" --file "$manifest_file_csv" >> $log
rc=$?
if [[ $rc != 0 ]]
then
    exit_error "$pid" $TASK_ID "Error ${rc}: validation returned an error. See the log for details."
fi

echo "All folders and files accounted for and valid." >> "$log"