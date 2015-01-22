#!/bin/sh
#
# ftp.sh
#
# ftp with the desired action
#
# Usage: ftp.sh [script name] [put command] [connection] [logfile name]
ftp_script=$1
put=$2
ftp_connection=$3
log=$4

echo "ftp_script: " $ftp_script
echo "put: " $put
echo "ftp_connection: " $ftp_connection
echo "log: " $log

echo "option batch continue" > $ftp_script
echo "option confirm off" >> $ftp_script
echo "option transfer binary" >> $ftp_script
echo "option reconnecttime 5" >> $ftp_script
echo "open ${ftp_connection} -explicittls -passive" >> $ftp_script
echo "$put" >> $ftp_script
echo "close" >> $ftp_script
echo "exit" >> $ftp_script

	#WinSCP /console /script="$(cygpath --windows $ftp_script)" /log:"$(cygpath --windows $log)"
	rc=$?
	if [ $rc -ge 0 ];
	then
		echo "zzzz"
		#rm -f "$ftp_script"    # added
		exit 0
	fi

echo "FTP failed." # >> $log
#rm -f "$ftp_script"
exit 1