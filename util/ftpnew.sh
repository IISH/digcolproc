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

#echo "option batch continue" > $ftp_scriptfile
#echo "option confirm off" >> $ftp_scriptfile
#echo "option transfer binary" >> $ftp_scriptfile
#echo "option reconnecttime 5" >> $ftp_scriptfile
#echo "open ${ftp_connection} -explicittls -passive" >> $ftp_scriptfile
#echo "$put" >> $ftp_scriptfile
#echo "close" >> $ftp_scriptfile
#echo "exit" >> $ftp_scriptfile

echo "debug 10" > $ftp_scriptfile
echo "set xfer:log true" >> $ftp_scriptfile
echo "set xfer:log-file \"${logfile}\"" >> $ftp_scriptfile
echo "open ${ftp_connection}" >> $ftp_scriptfile
echo "$put" >> $ftp_scriptfile
echo "bye" >> $ftp_scriptfile
#echo "close" >> $ftp_scriptfile
#echo "exit" >> $ftp_scriptfile

# TODO: try multiple times???

# TODO: logfile not working
#WinSCP /console /script="$(cygpath --windows $ftp_scriptfile)" /logfile:"$(cygpath --windows $logfile)"
#lftp -f $ftp_scriptfile --log=$logfile
lftp -f $ftp_scriptfile --log=$logfile
#echo $ftp_scriptfile
#echo $logfile
# TODO: catch return value of lftp
rc=$?
if [ $rc -ge 0 ];
then
	echo "FTP succeeded"
	echo "FTP succeeded" >> $logfile
	#rm -f "$ftp_scriptfile"    # added  # TODO: enable
	exit 0
fi

echo "FTP failed"
echo "FTP failed" >> $logfile
#rm -f "$ftp_scriptfile"  # TODO: enable
exit 1
