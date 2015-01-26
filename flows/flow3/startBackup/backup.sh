#!/bin/sh

# run.sh
#
# Mirror all folders which haven't been mirrored yet
#

# TODO: enable the config line
#source "${DIGCOLPROC_HOME}config.sh" $0 "$@"

# TODO: MOVE to config file
digcolproc_home=/usr/bin/digcolproc

# No folder created yet
statusNewDigitalMaterialCollection=1

# A folder has been created
statusFolderCreated=2

# Digital material has been uploaded
statusMaterialUploaded=3

# A backup of the digital material is being made
statusBackupRunning=4

# A backup of the digital material has been created
statusBackupFinished=5

# Digital material is ready for permanent storage
statusReadyForPermanentStorage=6

# Digital material is being uploaded to permanent storage
statusUploadingToPermanentStorage=7

# Digital material has been moved to permanent storage
statusMovedToPermanentStorage=8

# Load the PID
pid=$1
echo "DEBUG: \$pid = $pid (2)"

# generate random value
randomvalue=$(shuf -i1000-9999 -n1)

# TODO: MOVE to config file
ingestLocation="/tmp"

# TODO: MOVE to config file
logfile="/tmp/lftplogfile"

#
backupLocation="$ingestLocation/$pid"
#chown -R root "$backupLocation"    # TODO: waarom?

# TODO: MOVE to config file
ftp_connection="ftp://testgcu:testgcu123abc@ftp.iisg.nl"

# TODO: create put/get command, set local and remote directory
# format: putgetcommand="mirror --reverse --verbose /LOCAL /REMOTE"
putgetcommand="mirror --reverse --verbose /testgculocal /"

# Do the backup ...
"${DIGCOLPROC_HOME}/util/ftpnew.sh" "/tmp/lftpscriptfile.${randomvalue}" "${putgetcommand}" "${ftp_connection}" "${logfile}"
success=$?   # What is the exit code of the backup?

#chown -R "$owner" "$backupLocation"    # TODO: waarom?

# Update the status using the 'status' web service
if [ ${success} -eq 0 ]; # Did backup fail or succeed? ...
then
	# successful
	echo "DEBUG: Creating mirror was successful"

#	curl --data "pid=$pid&status=$statusBackupFinished&failure=false" "$applicationUrl/service/status"
else
	# not successful
	echo "DEBUG: Creating mirror was NOT successful"

#	curl --data "pid=$pid&status=$statusBackupFinished&failure=true" "$applicationUrl/service/status"
fi
