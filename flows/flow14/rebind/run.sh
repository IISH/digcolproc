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
rc=$?
if [[ $rc != 0 ]] ; then
    echo "create_concordancetable.py threw an error ${rc}">>$log
    exit 1
fi
if [ ! -f $file_concordancetable ]
then
    echo "Unable to create ${file_concordancetable}">>$log
    exit 1
fi


#-----------------------------------------------------------------------------------------------------------------------
# For each unitid in the csv, append the second item.
#-----------------------------------------------------------------------------------------------------------------------
while read line
do
    IFS=, read Objectnummer Inventarisnummer <<< "$line"
    if [ "$Objectnummer" == "Objectnummer" ] ; then
        echo "header"
    else
        pid="${na}/${archiveID}.${Inventarisnummer}"
        pid_url="${or}/mets/${pid}/2"
        wget --no-certificate "$pid_url" > "${work}"
    fi
done < $file_concordancetable

exit 0


