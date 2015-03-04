#!/bin/sh
#
# ftp.sh
#
# ftp with the desired action
#
# Usage: ftp.sh [script name] [put command] [connection] [logfile name]
ftp_scriptfile=$1
put=$2
ftp_connection=$3
logfile=$4

echo "debug 10" > $ftp_scriptfile
echo "set xfer:log true" >> $ftp_scriptfile
echo "set xfer:log-file \"${logfile}\"" >> $ftp_scriptfile
echo "set ssl:verify-certificate false">> $ftp_scriptfile
echo "set ftp:use-utf8 true">> $ftp_scriptfile
echo "open ${ftp_connection}" >> $ftp_scriptfile
echo "$put" >> $ftp_scriptfile
echo "bye" >> $ftp_scriptfile

# We do not want to log credentials here unless we have to.
if [ ! -z "$DIGCOLPROC_DEBUG" ] ; then
    echo "ftp_scriptfile:" >> $logfile
    cat $ftp_scriptfile >> $logfile
fi

to=10
for i in $(seq 1 $to)
do
    echo "Ftp files... attempt $i of $to">>$logfile
    lftp -f "$ftp_scriptfile"
    rc=$?
    if [[ $rc == 0 ]] ; then
        exit 0
    fi
done

echo "FTP failed" >> $logfile
exit 1
