#!/usr/bin/env python
#
# concordance_missing_masters.py
#

import os
import sys
import csv
import getopt


def parse_csv(fileset, concordance, new):
    columns = {}
    new_cc = open(new, 'w')

    with open(concordance, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for i, items in enumerate(reader):
            if i == 0:
                columns = identify_columns(items)
            elif not items[columns['master']]:
                jpeg = items[columns['jpeg']]
                master = jpeg.replace('/jpeg/', '/Tiff/', 1).replace('.jpg', '.tif', 1)
                items[columns['master']] = master

                master_path = master[master.find('/', 1):]
                jpeg_path = jpeg[jpeg.find('/', 1):]

                exit_code = os.system('convert -compress none ' + fileset + jpeg_path + ' ' + fileset + master_path)
                if exit_code != 0:
                    new_cc.close()
                    print('Error during conversion of ' + jpeg + ' to ' + master)
                    exit(exit_code)

            new_cc.write(','.join(items) + "\n")

    new_cc.close()


def identify_columns(items):
    columns = {}
    for i, val in enumerate(items):
        columns[val] = i
    return columns


def usage():
    print('Usage: concordance_missing_masters.py -f fileset; -c concordance table; -n new concordance table')


def main(argv):
    fileset = concordance = new = 0

    try:
        opts, args = getopt.getopt(argv, 'f:c:n:hd', ['fileset=', 'concordance=', 'new=', 'help', 'debug'])
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
        elif opt in ('-f', '--fileset'):
            fileset = arg
        elif opt in ('-c', '--concordance'):
            concordance = arg
        elif opt in ('-n', '--new'):
            new = arg

    assert fileset
    assert concordance
    assert new

    print('fileset=' + fileset)
    print('concordance=' + concordance)
    print('new=' + new + '\n')

    parse_csv(fileset, concordance, new)


if __name__ == '__main__':
    main(sys.argv[1:])
