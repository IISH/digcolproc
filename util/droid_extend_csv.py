#!/usr/bin/env python
#
# droid_extend_csv.py
#
# Parse the droid csv file
# - Replace missing Mime types with the default
# - Add a md5 checksum
# - Add a PID
# - introduce relative paths for the URI and FILE_PATH

import os
import os.path
import sys
import csv
from droid import Droid
import getopt
import re
import hashlib
import uuid

UNKNOWN_MIME_TYPE = 'application/octet-stream'

# Pattern for: aaa.bbb and aaa.123.bbb
SEQ_PATTERN = re.compile('^([a-zA-Z0-9]+)\.([a-zA-Z0-9]+)$|^([a-zA-Z0-9]+)\.([0-9]+)\.([a-zA-Z0-9]+)$')


def parse_csv(sourcefile, targetfile, na, fileset):
    manifest = open(targetfile, 'w')

    with open(sourcefile, 'rb') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for items in reader:
            if items[Droid.TYPE] == 'File':
                items[Droid.HASH] = hashfile(items[Droid.FILE_PATH])
                if not items[Droid.MIME_TYPE]:
                    items[Droid.MIME_TYPE] = UNKNOWN_MIME_TYPE
                items.append(na + '/' + str(uuid.uuid4()).upper())
                items.append(sequence(items[Droid.NAME]))
            elif items[Droid.TYPE] == 'TYPE':
                items.append("PID")
                items.append("SEQ")
            else:
                items.append("")
                items.append("")

            items[Droid.URI] = relative(items[Droid.URI], fileset)
            items[Droid.FILE_PATH] = relative(items[Droid.FILE_PATH], fileset)
            items = ['"{0}"'.format(item.replace('"', '""')) for item in items]  # Add the double quotes and ensure the values are escaped.
            manifest.write(','.join(items) + "\n")
    manifest.close()


# hashfile
# Calculate the hash by streaming the file
def hashfile(file, hasher=hashlib.md5(), blocksize=65536):
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


# Sequence
# Determine a potential sequence based on the file name:
# filename.sequence.extension
def sequence(name):
    matcher = SEQ_PATTERN.match(name)
    if matcher:
        if (matcher.group(1)):  # match for filename.extension
            # _objid = matcher.group(1) # the aaa in aaa.bbb
            _seq = ""
        else:
            # _objid = matcher.group(3) # the aaa in aaa.12345.ccc null null aaa 12345 ccc
            _seq = int(matcher.group(4))  # the 12345 in aaa.12345.ccc null null aaa 12345 ccc
    else:
        _seq = ""

    return _seq


def usage():
    print('Usage: droid_extend_csv.py -s source file; -t target file; -a access status; -f fileSet')


def main(argv):
    sourcefile = na = targetfile = fileset = 0

    try:
        opts, args = getopt.getopt(argv, 'n:s:t:f:hd',
                                   ['na=', 'sourcefile=', 'targetfile=', 'fileset=', 'help', 'debug'])
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


if __name__ == '__main__':
    main(sys.argv[1:])