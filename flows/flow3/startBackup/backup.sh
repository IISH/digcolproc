#!/bin/sh

# run.sh
#
# Mirror all folders which haven't been mirrored yet
#

# TODO: enable the config line
#source "${digcolproc_home}config.sh" $0 "$@"

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

echo "XXX DEBUG: \$pid = $pid"

# TODO: MOVE to config file
ingestLocation="/tmp"

#
backupLocation="$ingestLocation/$pid"
#chown -R root "$backupLocation"    # TODO: waarom?

# Do the backup ...
"${digcolproc_home}/util/ftpnew.sh" "/tmp/aaa" "PUT_HERE_PUT_COMMAND" "PUT_HERE_FTP_CONNECTION" "PUT_HERE_LOGFILE_NAME"
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
