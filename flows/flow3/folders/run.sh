#!/bin/bash

# run.sh
#
# Collects all folders from the acquisition database API that need to be created in the main local folder.
#

source "${digcolproc_home}setup.sh" $0 "$@"

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

flow3_applicationUrl="http://etc/"


# Call the 'folders' web service and extract the PIDs from the resulting JSON
pidsEval="curl '$flow3_applicationUrl/service/folders' | jq .pids[]"
pids=$(eval ${pidsEval})

# Create a folder for each PID
for pid in ${pids}
do
	# Remove the quotes around the PID
	pid="${pid%\"}"
	pid="${pid#\"}"

	# Create a folder for the PID
	mkdir -pm 764 "$flow3_ingestLocation/$pid"
	chown -R "$owner" "$flow3_ingestLocation"

	# Update the status using the 'status' web service
	if [ -d "$ingestLocation/$pid" ]
	then
		curl --data "pid=$pid&status=$statusFolderCreated&failure=false" "flow3_applicationUrl/service/status"
	else
		curl --data "pid=$pid&status=$statusFolderCreated&failure=true" "flow3_applicationUrl/service/status"
	fi
done



