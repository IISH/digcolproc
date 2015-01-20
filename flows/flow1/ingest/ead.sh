#!/bin/bash
#
# /ingest/ead.sh
#
# Sees if all items in the concordance table are present in the EAD document.
#
# Usage: eadValidate.sh

eadFile=$fileSet/$archiveID.xml
if [ ! -f $eadFile ] ; then
    echo "Unable to find the EAD document at $eadFile">>$log
	echo "The ingest was interrupted.">>$log
	exit -1
fi

archiveIDs=$work/archiveIDs.xml
if [ ! -f $archiveIDs ] ; then
    echo "Unable to find the archiveIDs file at $archiveIDs">>$log
	echo "The ingest was interrupted.">>$log
	exit -1
fi

ead=$work/$archiveID.xml
groovy $global_home/ead.groovy "$eadFile" "$archiveIDs" $ead >> $log
if [ -f $ead ] ; then
    echo "See the EAD with added daoloc elements at" >> $log
    $ead >> $log
else
    echo "Unable to add daoloc elements to $ead" >> $ead
fi
