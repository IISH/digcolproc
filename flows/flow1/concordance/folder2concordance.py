#!/usr/bin/env python
#
# folder2concordance.py
#
# Reconstructs a CSV concordance table based on a conventional folder setup.
#
# The folder setup is:
# [ARCHIVAL ID]
# Tiff
#         [Inventory number]
#             [Files]
import getopt
import sys
import os


def usage():
    print('Usage: folder2concordance.py --fileset [fileSet] --target [target concordance file]')

CR = "\n"

def parse_csv(fileset):
    concordance_file = fileset + os.path.dirname(fileset) + '.csv'
    if os.path.exists(concordance_file):
        print('Concordance file already exists in ' + concordance_file)
        sys.exit(-1)

    tiff_folder = fileset + '/Tiff'
    if not os.path.exists(tiff_folder):
        print(tiff_folder + ' not found.')
        sys.exit(-1)

    fh = open(concordance_file, 'w')
    fh.write('"Tiff, jpeg"' + CR)

    for item in os.listdir(tiff_folder):
        item_folder = tiff_folder + '/' + item
        for filename in os.listdir(item_folder):
            name_extension = filename.split('.')
            name=name_extension[0]
            #extension=name_extension[1]
            item_sequence = name.split('_')
            item = item_sequence[0]
            sequence=item_sequence[1]
    fh.close()


def main(argv):
    fileset = None

    try:
        opts, args = getopt.getopt(argv, 'f:h', ['fileset=', 'help'])
    except getopt.GetoptError as e:
        print("Opt error: " + e.msg)
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        if opt in ('-f', '--fileset'):
            fileset = arg

    assert fileset

    parse_csv(fileset)


if __name__ == '__main__':
    main(sys.argv[1:])