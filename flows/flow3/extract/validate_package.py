#!/usr/bin/env python
#
# validate_package.py
#
# Now verify each file that is in the list. Does it exist and does the checksum match.


import csv
import getopt
import hashlib
import os
import sys


def parse_file(fs_parent, file):
    errors = 0
    with open(file, 'rb') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for items in reader:
            type, filename, expected_md5 = items
            file = fs_parent + '/' + filename
            if type == 'D':
                if os.path.isdir(file):
                    print 'OK... ' + file
                else:
                    errors += 1
                    print 'BAD... directory not found: ' + file
            elif type == 'F':
                if os.path.isfile(file):
                    actual_md5=hashfile(file)
                    if actual_md5 == expected_md5:
                        print 'OK... file ' + file
                    else:
                        errors += 1
                        print 'BAD... file checksum mismatch ' + file
                else:
                    print 'BAD... file not found: ' + file
                    errors += 1
            else:
                print 'Unrecognized type ' + type

    if errors:
        print 'Errors: {}'.format(errors)
        sys.exit(1)
    else:
        print 'All ok'
        sys.exit(0)


# hashfile
# Calculate the hash by streaming the file
def hashfile(file, blocksize=32768):
    _file = open(file, 'r')
    _blocksize = blocksize
    hasher = hashlib.md5()
    while _blocksize == blocksize:
        buf = _file.read(blocksize)
        hasher.update(buf)
        _blocksize = len(buf)

    _file.close()
    return hasher.hexdigest()


def usage():
    print('Usage: validate_package.py  --fs_parent [path to the parent of the fileset] --file [file to csv document]')


def main(argv):
    file = fs_parent = None

    try:
        opts, args = getopt.getopt(argv, 'f:p:h', ['file=', 'fs_parent=', 'help'])
    except getopt.GetoptError as e:
        print("Opt error: " + e.msg)
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-f', '--file'):
            file = arg
        elif opt in ('-p', '--fs_parent'):
            fs_parent = arg
        else:
            print("Unknown argument: " + opt)
            sys.exit(1)

    assert file
    parse_file(fs_parent, file)


if __name__ == '__main__':
    main(sys.argv[1:])
