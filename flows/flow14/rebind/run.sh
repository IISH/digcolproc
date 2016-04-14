#!/bin/bash
#
# run.sh
#
# Retrieve the EAD from the OAI2 server
# Obtain the item numbers in: //ead:did/ead:unitid/4074
# Bind the PID and qualifiers to the expected resolvable URLs


#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh


#-----------------------------------------------------------------------------------------------------------------------
# Download the EAD file
#-----------------------------------------------------------------------------------------------------------------------
file="${work}/${oai_request}.txt"
pid="${na}/${archiveID}"
oai_request="${oai}?verb=GetRecord&amp;identifier=oai:socialhistoryservices.org:${pid}&amp;metadataPrefix=ead"
rm $file
wget --no-check-certificate -O $file
if [ ! -f $file ]
then
    echo "Unable to download to ${file}">>$log
    exit 1
fi


#-----------------------------------------------------------------------------------------------------------------------
# Pull out the unitid values. Create a concordance list as used by the PID bind procedure.
#-----------------------------------------------------------------------------------------------------------------------
file_concordancetable="${work}/${archiveID}"
python create_concordancetable.py --xml_file="$file" --xsl_file="create_concordancetable.xsl" --result_file="$file_concordancetable" >> $log



exit 0


