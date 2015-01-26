#!/bin/bash

# run.sh
#
# Usage:
# validate.sh [na] [folder name]

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"

cd "${DIGCOLPROC_HOME}flow4/validate"
source ./run.sh

cd "${DIGCOLPROC_HOME}ingest"
source ./run.sh

exit 0