#!/bin/bash
#
# /ingest/ead.sh
#
# Sees if all items in the concordance table are present in the EAD document. And vise versa.
#
# Usage: eadValidate.sh

eadFile=$fileSet/$archiveID.xml
if [ ! -f $eadFile ] ; then
    echo "Unable to find the EAD document at $eadFile">>$log
	echo "The validation was interrupted.">>$log
	exit -1
fi

archiveIDs=$work/archiveIDs.xml
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><list>" > $archiveIDs

while read line
do
    IFS=, read objnr ID master jpeg volgnr PID <<< "$line"
    if [[ $volgnr == 1 ]] ; then
        echo "<item>$ID</item>" >> $archiveIDs
    fi
done < $cf

echo "</list>" >> $archiveIDs

eadReport=$work/ead.report.html
groovy $global_home/ead.groovy "$eadFile" "$archiveIDs" $eadReport >> $log
if [ -f $eadReport ] ; then
    echo "See the EAD validation for inventarisnummer and unitid matches at" >> $log
    echo $eadReport >> $log
else
    echo "Unable to validate $eadFile" >> $log
fi
