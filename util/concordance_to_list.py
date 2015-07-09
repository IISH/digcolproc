#!/usr/bin/env python
#
# concordance_to_list.py
import getopt
import sys
import csv


def usage():
    print('Usage: concordance_to_list.py '
          '--concordance [concordance file] --filter [name of column to filter] (optional)')


def parse_csv(concordance, filter):
    columns = {}
    last_items = None
    with open(concordance, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for i, items in enumerate(reader):
            if i == 0:
                columns = identify_columns(items)
            elif not filter or last_items[columns[filter]] != items[columns[filter]]:
                print_items(items, columns)

            last_items = items


def print_items(items, columns):
    items_to_print = [items[columns['objnr']], items[columns['ID']], items[columns['volgnr']], items[columns['PID']]]

    print(items[columns['master']] + ',' + ','.join(items_to_print))
    for text_column in columns['text']:
        if items[text_column]:
            print(items[text_column] + ',' + ','.join(items_to_print))


def identify_columns(items):
    columns = {}
    for i, val in enumerate(items):
        if val.startswith('text '):
            if 'text' in columns:
                columns['text'].append(i)
            else:
                columns['text'] = [i]
        else:
            columns[val] = i
    return columns


def main(argv):
    concordance = filter = 0

    try:
        opts, args = getopt.getopt(argv, 'c:p:hd', ['concordance=', 'filter=', 'help', 'debug'])
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
        elif opt in ('-f', '--filter'):
            filter = arg

    assert concordance
    parse_csv(concordance, filter)


if __name__ == '__main__':
    main(sys.argv[1:])