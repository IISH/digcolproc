#!/bin/bash
#
# /ingest/run.sh
#
# Creates level2 images from level1. Or if there is no level 1, the masters in the Tiff folder.
#
# Usage: run.sh [na] [fileSet] [work directory]

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"

targetLevel=level2
originals_folder=$fileSet/.level1
echo "Start creating custom level 2...">>$log
if [ ! -d $originals_folder ] ; then
    originals_folder=$fileSet/jpeg
fi
if [ ! -d $originals_folder ] ; then
    originals_folder=$fileSet/Tiff
fi

if [ ! -d $originals_folder ] ; then
    echo "No folders found for $originals_folder">>$log
    exit 0
fi

dir_target=$fileSet/.$targetLevel

for item_folder in $originals_folder/*
do
    item=$(basename $item_folder)
    find $item_folder -type f > $work/$targetLevel.txt
    while read file_original
    do
		folder_item=$dir_target/$item
		if [ ! -d $folder_item ] ; then
			mkdir -p $folder_item
		fi
        filename=$(basename $file_original)
        file_target=$folder_item/${filename%%.*}
        imparms=$(identify -format 'h=%h,w=%w,x=%x,y=%y,z=%z' $file_original)
        php ./image.derivative.php -i $(cygpath --windows $file_original) -o $(cygpath --windows $file_target) -l $targetLevel -p "$imparms" >> $log
        #php ./image.derivative.php -i $file_original -o $file_target -l $targetLevel -p "$imparms"
        rc=$?
        if [[ $rc != 0 ]] ; then
            echo "Problem creating $dir_target">>$log
        fi
    done < $work/$targetLevel.txt

    # Create some preview material.
    metsfile=$dir_target/$item/mets.xml
    echo "<?xml version='1.0' encoding='UTF-8'?><mets xmlns='http://www.loc.gov/METS/' xmlns:xlink='http://www.w3.org/1999/xlink' \
          xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' \
          xsi:schemaLocation='http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/mets.xsd' \
          OBJID='10622/$archiveID'> \
        <fileSec>" > $metsfile

    id=0
    for fileGrp in 'archive image' 'hires reference image' 'reference image' 'thumbnail image'
    do
        echo "<fileGrp ID='master' USE='$fileGrp'>" >> $metsfile
        let id++;
        if [[ $id == 1 ]] ; then
            t="master"
        fi
        if [[ $id == 2 ]] ; then
            t="level1"
        fi
        if [[ $id == 3 ]] ; then
            t="level2"
        fi
        if [[ $id == 4 ]] ; then
            t="level3"
        fi

        count=0
        while read file_original
        do
            let count++;
            filename=$(basename $file_original)
            filename=${filename%%.*}
            echo "<file CHECKSUM='5ca5e5ddec89d0e0ed196ee496b4e3db' CHECKSUMTYPE='MD5' CREATED='2013-04-24T26:09:16Z' ID='$t$count' \
                      MIMETYPE='image/jpeg' SIZE='11366428'> \
                    <FLocat LOCTYPE='URL' \
                            xlink:href='http://node-121.dev.socialhistoryservices.org/mets/$na/$archiveID/.level2/$item/$filename.jpg' \
                            xlink:title='$filename.jpg' xlink:type='simple'/> \
                </file>" >> $metsfile
        done < $work/$targetLevel.txt
        echo "</fileGrp>" >> $metsfile
    done

    echo "</fileSec> \
    <structMap TYPE='physical'> \
        <div>" >> $metsfile

    count=0
    while read file_original
    do
        let count++;
        echo "<div ID='g$i' LABEL='Page $i' ORDER='$count' TYPE='page'> \
                <fptr FILEID='master$count'/> \
                <fptr FILEID='level1$count'/> \
                <fptr FILEID='level2$count'/> \
                <fptr FILEID='level3$count'/> \
            </div>">>$metsfile
    done < $work/$targetLevel.txt

    echo "</div> \
    </structMap></mets>" >> $metsfile

    metshtml=$dir_target/$item/mets.html
    echo "<!DOCTYPE html> \
        <html> \
        <body> \
<link href='http://visualmets.socialhistory.org/rest/resources/css/themes/iisg/style.css' rel='stylesheet' type='text/css' media='all' /> \
<script type='text/javascript' src='http://visualmets.socialhistory.org/rest/resources/js/mets2viewer.min.js'></script> \
<script type='text/javascript'> \
	(function($){ \
	\$(document).ready(function(){ \
		\$('#myMetsViewer').mets2Viewer({ \
		'initialize' : { \
		'metsId' : 'http://node-121.dev.socialhistoryservices.org/mets/$na/$archiveID/.level2/$item/mets.xml', \
		'pager' : { \
		'start' : 0, \
		'rows' : -1 \
		} \
		} \
		}); \
	}); \
	})(jQuery); \
</script> \
<div id='parent' style='width: 1000px; height: 500px;'> \
	<div id='myMetsViewer'></div> \
</div> \
</body> \
</html>" > $metshtml

done

echo "Upload files...">>$log
${DIGCOLPROC_HOME}util/ftp.sh "$ftp_script" "synchronize remote -mirror -criteria=size $fileSet_windows\.$targetLevel $archiveID/.$targetLevel" "$flow_ftp_connection" "$log"
rc=$?
if [[ $rc != 0 ]] ; then
    exit -1
fi

echo $(date)>>$log
echo "Done $targetLevel update.">>$log