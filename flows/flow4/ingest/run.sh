#!/bin/bash

# run.sh
#
# Usage:
# validate.sh [na] [folder name]

source "${digcolproc_home}setup.sh" $0 "$@"

cd "${digcolproc_home}flow4/validate"
source ./run.sh

cd "${digcolproc_home}ingest"
source ./run.sh

exit 0