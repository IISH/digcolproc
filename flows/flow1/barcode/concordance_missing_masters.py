#!/usr/bin/env python
#
# concordance_missing_masters.py
#

import os
import sys
import csv
import getopt


def parse_csv(fileset, concordance, new):
    prev_seqnr = '-1'
    columns = {}
    new_cc = open(new, 'w')

    with open(concordance, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for i, items in enumerate(reader):
            if i == 0:
                columns = identify_columns(items)
            else:
                seqnr = items[columns['volgnr']]
                if seqnr == '1' and prev_seqnr != '0':
                    jpeg = items[columns['jpeg']].replace(seqnr + '.jpg', '0.jpg', 1)
                    master = jpeg.replace('/jpeg/', '/Tiff/', 1).replace('.jpg', '.tif', 1)

                    jpeg_path = jpeg[jpeg.find('/', 1):]
                    if os.path.isfile(fileset + jpeg_path):
                        create_master_file(fileset, master, jpeg)

                        items_zero = list(items)
                        items_zero[columns['master']] = master
                        items_zero[columns['jpeg']] = jpeg
                        items_zero[columns['volgnr']] = '0'
                        new_cc.write(','.join(items_zero) + "\n")

                if not items[columns['master']]:
                    jpeg = items[columns['jpeg']]
                    master = jpeg.replace('/jpeg/', '/Tiff/', 1).replace('.jpg', '.tif', 1)
                    items[columns['master']] = master

                    create_master_file(fileset, master, jpeg)

                prev_seqnr = seqnr

            new_cc.write(','.join(items) + "\n")

    new_cc.close()


def identify_columns(items):
    columns = {}
    for i, val in enumerate(items):
        columns[val] = i
    return columns


def create_master_file(fileset, master, jpeg):
    master_path = master[master.find('/', 1):]
    jpeg_path = jpeg[jpeg.find('/', 1):]

    master_file = fileset + master_path
    if os.path.isfile(master_file):
        print('Skipping ' + master_file + ' because the master file already exists.')
    else:
        print('converting')
        #exit_code = os.system('convert -compress none ' + fileset + jpeg_path + ' ' + master_file)
        if False: #exit_code != 0:
            print('Error during conversion of ' + jpeg + ' to ' + master)
            os.remove(master_file)  # undo failed attempt.
            exit(exit_code)


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