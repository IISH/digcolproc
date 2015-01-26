#!/bin/bash
#
# ftp.sh
#
# ftp with the desired action
#
# Usage: ftp.sh [script name] [put command] [log file]
ftp_script=$1
put=$2
ftp_connection=$3
log=$4

echo "option batch continue">$ftp_script
echo "option confirm off">>$ftp_script
echo "option transfer binary">>$ftp_script
echo "option reconnecttime 5">>$ftp_script
echo "open ${ftp_connection} -explicittls -passive">>$ftp_script
echo "$put">>$ftp_script
echo "close">>$ftp_script
echo "exit">>$ftp_script

to=10
for i in $(seq 1 $to)
do
    echo "Ftp files... attempt $i of $to">>$log
    WinSCP /console /script="$(cygpath --windows $ftp_script)" /log:"$(cygpath --windows $log)"
    rc=$?
    if [[ $rc == 0 ]] ; then
        exit 0
    fi
done

echo "FTP failed for $to times in a row.">>$log
rm -f "$ftp_script"
exit -1