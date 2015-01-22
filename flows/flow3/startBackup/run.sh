#!/bin/sh

# run.sh
#
# Mirror all folders which haven't been mirrored yet
#

# Determine location of this script
script="$(readlink -f ${BASH_SOURCE[0]})"
scriptLocation="$(dirname ${script})"

# TODO: enable the config line
#source "${digcolproc_home}config.sh" $0 "$@"

# TODO: MOVE to config file
#flow3_applicationUrl="http://etc/"
#flow3_applicationUrl="http://node-164.dev.socialhistoryservices.org/service/folders"
flow3_applicationUrl="http://10.0.0.100:8080" # gcu local

# TODO: MOVE to config file
scriptLocation="/usr/bin/digcolproc/flows/flow3/startBackup"

# Call the 'startBackup' web service and extract the PIDs from the resulting JSON
pidsEval="curl '$flow3_applicationUrl/service/startBackup' | jq .pids[]"
pids=$(eval ${pidsEval})

# Create mirror folder for each PID
for pid in ${pids}
do
	# Remove the quotes around the PID
	pid="${pid%\"}"
	pid="${pid#\"}"

	echo "DEBUG: \$pid = $pid"

	# Start backup for the current PID as a seperate process
	"$scriptLocation/backup.sh" "$pid" &
done
