#!/bin/bash
#
# /concordance/run.sh
#
# Reconstructs a concordance CSV
#
# Usage: run.sh [na] [fileSet] [work directory]

source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"

echo "Start creating a concordance table...">>$log
python folder2concordance.py --fileset $fileSet
