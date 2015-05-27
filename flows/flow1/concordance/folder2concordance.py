#!/usr/bin/env python
#
# folder2concordance.py
#
# Reconstructs a CSV concordance table based on a conventional folder setup.
#
# The folder setup is:
# [ARCHIVAL ID]
# [ARCHIVAL ID]/ARCHIVAL ID.bad.csv
#     Tiff
#         [Inventory number]
#             [Files]
#
# The end result is a csv file called:
# [ARCHIVAL ID]/ARCHIVAL ID.good.csv
import getopt
import sys
import os


def usage():
    print('Usage: folder2concordance.py --fileset [fileSet]')


CR = "\n"

# our dictionary with objectnumber and inventory numbers
list = {}


def parse_csv(fileset):
    archival_id = os.path.basename(fileset)
    concordance_file_good = fileset + '/' + archival_id + '.good.csv'

    concordance_file_bad = fileset + '/' + archival_id + '.bad.csv'
    if not os.path.exists(concordance_file_bad):
        print('Expecting a badly coded file at ' + concordance_file_bad)
        sys.exit(-1)

    tiff_folder = fileset + '/Tiff'
    if not os.path.exists(tiff_folder):
        print(tiff_folder + ' not found.')
        sys.exit(-1)

    with open(concordance_file_bad) as o:
        for line in o:
            objectnumber_inventorynumber = line.strip().split(',')
            if len(objectnumber_inventorynumber) > 1:
                objectnumber = objectnumber_inventorynumber[0]
                inventorynumber = objectnumber_inventorynumber[1]
                list[objectnumber] = inventorynumber
            else:
                print "Warning: line cannot be parsed: " + line

    fh = open(concordance_file_good, 'w')
    fh.write('objnr,ID,master,jpeg,volgnr' + CR)

    for objectnumber in os.listdir(tiff_folder):
        item_folder = tiff_folder + '/' + objectnumber
        for filename in os.listdir(item_folder):
            # filename is for example ARCH00860_1_00005.tif
            name_extension = filename.split('.')
            name = name_extension[0]  # ARCH00860_1_00005
            #extension=name_extension[1]
            na_item_sequence = name.split('_')
            #na = na_item_sequence[0]
            objectnumber = na_item_sequence[1]  # 1
            sequence = str(int(na_item_sequence[2]))  # 00005
            jpeg_file = relative(fileset + '/jpeg/' + objectnumber + '/' + name + '.jpeg', fileset)
            filename = relative(fileset + '/' + objectnumber + '/' + name, fileset)
            if list.has_key(objectnumber):
                inventorynumber = list[objectnumber]
                fh.write(objectnumber + ',' + inventorynumber + ',' + filename + '.tif' + ',' + filename + '.jpg' + ',' + sequence + CR)
            else:
                print "Warning: no such objectnumber: " + objectnumber
    fh.close()


def relative(path, fileset):
    p = '/' + os.path.basename(fileset)
    return path.replace(fileset, p)


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