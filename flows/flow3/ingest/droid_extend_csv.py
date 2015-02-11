#!/usr/bin/env python
#
# droid_extend_csv.py
#
# Parse the droid csv file
# - Replace missing Mime types with the default
# - Add a md5 checksum
# - Add a PID
# - introduce relative paths for the URI and FILE_PATH

import csv
from droid import Droid
import getopt
import hashlib
import os.path
import sys
import uuid

UNKNOWN_MIME_TYPE = 'application/octet-stream'


def main(argv):

    sourcefile=na=targetfile=fileset=0

    try:
        opts, args = getopt.getopt(argv, 'n:s:t:f:hd', ['na=', 'sourcefile=', 'targetfile=', 'fileset=', 'help', 'debug'])
    except getopt.GetoptError:
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt == '-d':
            global _debug
            _debug = 1
        elif opt in ('-s', '--sourcefile'):
            sourcefile = arg
        elif opt in ('-t', '--targetfile'):
            targetfile = arg
        elif opt in ('-n', '--na'):
            na = arg
        elif opt in ('-f', '--fileset'):
            fileset = arg

    assert sourcefile
    assert targetfile
    assert na
    assert fileset
    print('sourcefile=' + sourcefile)
    print('targetfile=' + targetfile)
    print('na=' + na)
    print('fileset=' + fileset)

    parse_csv(sourcefile, targetfile, na, fileset)


def parse_csv(sourcefile, targetfile, na, fileset):

    manifest=open(targetfile, 'w')

    with open(sourcefile, 'rb') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for items in reader:
            if items[Droid.TYPE] == 'File':
                items[Droid.HASH] = hashfile(items[Droid.FILE_PATH])
                items.append(na + '/' + str(uuid.uuid4()).upper())
                if not items[Droid.MIME_TYPE]: items[Droid.MIME_TYPE] = UNKNOWN_MIME_TYPE
            elif items[Droid.TYPE] == 'TYPE':
                items.append("PID")
            else:
                items.append("")

            items[Droid.URI] = relative(items[Droid.URI], fileset)
            items[Droid.FILE_PATH] = relative(items[Droid.FILE_PATH], fileset)
            items = ['"{0}"'.format(item) for item in items] # Add the double quotes
            manifest.write(",".join(items)+ "\n")
    manifest.close()


# hashfile
# Calculate the hash by streaming the file
def hashfile(file, hasher = hashlib.md5(), blocksize=65536):
    _file = open(file, 'r')
    buf = _file.read(blocksize)
    while len(buf) > 0:
        hasher.update(buf)
        buf = _file.read(blocksize)
    return hasher.hexdigest()


# relative
# Turn the absolute path into a relative one
def relative(path, fileset):
    archivalID = '/' + os.path.basename(fileset)
    return path.replace(fileset, archivalID)


def usage():
    print('Usage: droid_extend_csv.py -s source file; -t target file; -a access status; -f fileSet')


if __name__ == '__main__':
    main(sys.argv[1:])