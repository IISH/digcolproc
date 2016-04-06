#!/usr/bin/env python
#
# report_ingest.py
#
# Usage
# report_ingest.py -i [instruction file]
#
# Description
# Report if the files that are mentioned in the instruction now live in the object repository.
#
# Return status
# Exits with zero when all files are accounted for. Else return 2.


import getopt
import sys


def usage():
    print('Usage: report_ingest.py [-d] -i [instruction]')


def main(argv):
    instruction = 'instruction.xml'

    try:
        opts, args = getopt.getopt(argv, 'i', ['instruction='])
    except getopt.GetoptError:
        usage()
        sys.exit(2)

    for opt, arg in opts:
        if opt in ('-i', '--instruction'):
            instruction = arg

    assert instruction
    print('instruction=' + instruction + '\n')



if __name__ == '__main__':
    main(sys.argv[1:])
