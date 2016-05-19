#!/bin/sh
#
# ftp.sh
#
# ftp with the desired action
#
# Usage: ftp.sh [script name] command [ftp commands] [connection] [logfile name]
ftp_scriptfile=$1
command=$2
ftp_connection=$3
logfile=$4

echo "debug 10" > $ftp_scriptfile
#echo "set xfer:log true" >> $ftp_scriptfile
#echo "set xfer:log-file \"${logfile}\"" >> $ftp_scriptfile
echo "set ssl:verify-certificate false">> $ftp_scriptfile
echo "set ftp:passive-mode true">> $ftp_scriptfile
echo "set ftp:ssl-protect-data true">> $ftp_scriptfile
echo "open ${ftp_connection}" >> $ftp_scriptfile
echo "$command" >> $ftp_scriptfile
#echo "close" >> $ftp_scriptfile
echo "bye" >> $ftp_scriptfile

# We do not want to log credentials here unless we have to.
if [ ! -z "$DIGCOLPROC_DEBUG" ] ; then
    echo "ftp_scriptfile:" >> $logfile
    cat $ftp_scriptfile >> $logfile
fi

lftp -f "$ftp_scriptfile" >> "$logfile" 2>&1
rc=$?
if [[ $rc == 0 ]] ; then
    exit 0
fi

echo "FTP failed" >> $logfile
exit 1
