#!/bin/bash

# run.sh
#
# Collects all folders from the acquisition database API that need to be created in the main local folder.
#

# TODO: enable the source line
###digcolproc_home="../../../"   # test
#source "${digcolproc_home}setup.sh" $0 "$@"

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

# TODO: MOVE to config file (puppet)
#flow3_applicationUrl="http://etc/"
#flow3_applicationUrl="http://node-164.dev.socialhistoryservices.org/service/folders"
flow3_applicationUrl="http://10.0.0.100:8080" # gcu local

# TODO: MOVE to config file (puppet)
flow3_ingestLocation=/tmp

# TODO: MOVE to config file (puppet)
owner="root:root"

# Call the 'folders' web service and extract the PIDs from the resulting JSON
pidsEval="curl '$flow3_applicationUrl/service/folders' | jq .pids[]"
pids=$(eval ${pidsEval})

# Create a folder for each PID
for pid in ${pids}
do
	# Remove the quotes around the PID
	pid="${pid%\"}"
	pid="${pid#\"}"

	echo "DEBUG: \$pid = $pid"

	# Create a folder for the PID
#	echo "DEBUG: mkdir -pm 764 $flow3_ingestLocation/$pid"
#	mkdir -pm 764 "$flow3_ingestLocation/$pid"
	echo "DEBUG: mkdir -p $flow3_ingestLocation/$pid"
	mkdir -p "$flow3_ingestLocation/$pid"
	echo "DEBUG: chmod -R 764 $flow3_ingestLocation/$pid"
	chmod -R 764 "$flow3_ingestLocation/$pid"
	echo "DEBUG: chown -R $owner $flow3_ingestLocation"
	chown -R "$owner" "$flow3_ingestLocation/$pid"

	# check if the directory already exists
	if [ -d "$flow3_ingestLocation/$pid" ];
	then
		# directory exists
		echo "DEBUG: Directory created: $flow3_ingestLocation/$pid"

		# Update the status using the 'status' web service
		echo "DEBUG: curl --data pid=$pid&status=$statusFolderCreated&failure=false $flow3_applicationUrl/service/status"
		curl --data "pid=$pid&status=$statusFolderCreated&failure=false" "$flow3_applicationUrl/service/status"
	else
		# directory doesn't exist
		echo "DEBUG: Directory does not exists: $flow3_ingestLocation/$pid"

		# Update the status using the 'status' web service
		echo "DEBUG: curl --data pid=$pid&status=$statusFolderCreated&failure=true $flow3_applicationUrl/service/status"
		curl --data "pid=$pid&status=$statusFolderCreated&failure=true" "$flow3_applicationUrl/service/status"
	fi
done
