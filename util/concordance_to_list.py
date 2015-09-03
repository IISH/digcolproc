#!/usr/bin/env python
#
# concordance_to_list.py
import getopt
import sys
import csv


def usage():
    print('Usage: concordance_to_list.py --concordance [concordance file]')


def parse_csv(concordance):
    columns = {}
    last_items = None
    with open(concordance, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for i, items in enumerate(reader):
            if i == 0:
                columns = identify_columns(items)
            elif not filter or last_items[columns['ID']] != items[columns['ID']]:
                print_items(items, columns)

            last_items = items


def print_items(items, columns):
    items_to_print = [items[columns['objnr']], items[columns['ID']]]
    print(','.join(items_to_print))


def identify_columns(items):
    columns = {}
    for i, val in enumerate(items):
        columns[val] = i
    return columns


def main(argv):
    concordance = 0

    try:
        opts, args = getopt.getopt(argv, 'c:hd', ['concordance=', 'help', 'debug'])
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
        elif opt in ('-c', '--concordance'):
            concordance = arg

    assert concordance
    parse_csv(concordance)


if __name__ == '__main__':
    main(sys.argv[1:])