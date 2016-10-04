#!/bin/bash

# run.sh
#
# Usage:
# run.sh [na] [folder name]
#
# This script retrieves a package from the object repository and unpacks it.
# It expects a manifest to be present to validate each folder and file.



#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh
pid=$na/$archiveID
TASK_ID=$EXTRACT



#-----------------------------------------------------------------------------------------------------------------------
# Commence job. Tell what we are doing
#-----------------------------------------------------------------------------------------------------------------------
call_api_status $pid $TASK_ID $RUNNING



#-----------------------------------------------------------------------------------------------------------------------
# Get the manifest
#-----------------------------------------------------------------------------------------------------------------------
manifest_file="$work/manifest.xml"
manifest_url="${or}/mets/${pid}"
wget -O "$manifest_file" --header="Authorization: bearer ${pidwebserviceKey}" --no-check-certificate "$manifest_url"
rc=$?
if [[ $rc != 0 ]] || [ ! -f "$manifest_file" ]
then
    exit_error "$pid" $TASK_ID "Unable to download a file ${manifest_url}"
fi



#-----------------------------------------------------------------------------------------------------------------------
# For each file in the manifest, download the rar
#-----------------------------------------------------------------------------------------------------------------------
package_dir="${work_base}/package"
rm -rf "package_dir"
mkdir -p "$package_dir"
url_from_manfest="${work}/manifest_urls.txt"
python ${DIGCOLPROC_HOME}/util/xslt_transformer.py --xml_file="$manifest_file" --xsl_file="url_from_manfest.xsl" > "$url_from_manfest"
while read line
do
    IFS=, read id title <<< "$line"
    url="${or}/file/master/${id}"
    file="${package_dir}/${title}"
    wget -O "$file" --header="Authorization: bearer ${pidwebserviceKey}" --no-check-certificate "$url"
    rc=$?
    if [[ $rc != 0 ]] || [ ! -f "$file" ]
    then
        rm "${file}"
        exit_error "$pid" $TASK_ID "Unable to download a file ${file}"
    fi
done < "$manifest_urls"



#-----------------------------------------------------------------------------------------------------------------------
# Extract the package amd cleanup the rar files.
#-----------------------------------------------------------------------------------------------------------------------
package="${package_dir}/${archiveID}"
unrar x "$package" "$package_dir" >> $log
rc=$?
if [[ $rc != 0 ]]
then
    exit_error "$pid" $TASK_ID "Unable to unpack ${package}"
fi
rm "${package_dir}/*.rar"
rm "$manifest_file"


#-----------------------------------------------------------------------------------------------------------------------
# Validate the files with the manifest that was in the package
#-----------------------------------------------------------------------------------------------------------------------
file_from_manifest="${work}/file_from_manifest.txt"
python ${DIGCOLPROC_HOME}/util/xslt_transformer.py --xml_file="$manifest_file" --xsl_file="file_from_manifest.xsl" > "$file_from_manifest"

exit 0