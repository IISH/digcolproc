#!/usr/bin/env python
#
# concordance_to_directory.py
import os
import csv
import sys
import getopt
import shutil
import os.path


def usage():
    print('Usage: concordance_to_directory.py --concordance [concordance file] --fileset [file set]')


def init_fileset(fileset):
    fileset = os.path.normpath(fileset)
    if not os.path.exists(fileset):
        print('The file set ' + fileset + ' was not found!')
        exit(1)
    os.chdir(fileset)

    if not os.path.exists(os.path.join(fileset, 'tmp')):
        os.mkdir('tmp')
    os.chdir(os.path.join(fileset, 'tmp'))


def parse_csv(concordance):
    columns = {}
    with open(concordance, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for i, items in enumerate(reader):
            if i == 0:
                columns = identify_columns(items)
            else:
                move_files(columns, items)


def identify_columns(items):
    columns = {'text': {}}
    for i, val in enumerate(items):
        if val.startswith('text'):
            columns['text'][val] = i
        else:
            columns[val] = i
    return columns


def move_files(columns, items):
    archive_id = os.path.basename(os.path.dirname(os.getcwd()))
    dir_name = archive_id + '.' + items[columns['objnr']]
    volgnr = items[columns['volgnr']]

    move_files_for(dir_name, items[columns['master']], 'archive image', volgnr)

    if 'jpeg' in columns:
        move_files_for(dir_name, items[columns['jpeg']], 'archive image/.level1', volgnr)

    for name in columns['text']:
        move_files_for(dir_name, items[columns['text'][name]], name, volgnr)


def move_files_for(parent_dir, cur_path, dir_name, volgnr):
    if cur_path:
        if cur_path.startswith('/'):
            cur_path = cur_path[1:]
        parent_path = os.path.dirname(os.path.dirname(os.getcwd()))
        cur_path = os.path.join(parent_path, os.path.normpath(cur_path))

        if os.path.exists(cur_path):
            new_dir = os.path.join(parent_dir, dir_name)
            new_filename = parent_dir + '.' + volgnr + os.path.splitext(cur_path)[1]

            try:
                os.makedirs(new_dir)  # Python 3.2 : exist_ok=True
            except OSError:
                if not os.path.isdir(new_dir):
                    raise

            os.rename(cur_path, os.path.join(new_dir, new_filename))


def end_fileset(fileset):
    fileset = os.path.normpath(fileset)
    os.chdir(fileset)

    for filename in os.listdir(os.path.join(fileset, 'tmp')):
        shutil.move(os.path.join(fileset, 'tmp', filename), os.path.join(fileset, filename))

    remove_empty_folders(fileset)


def remove_empty_folders(fileset):
    for filename in os.listdir(fileset):
        path = os.path.join(fileset, filename)
        if os.path.isdir(path):
            remove_empty_folders(path)
            if not os.listdir(path):
                os.rmdir(path)


def main(argv):
    concordance = fileset = 0

    try:
        opts, args = getopt.getopt(argv, 'c:f:hd', ['concordance=', 'fileset=', 'help', 'debug'])
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
        elif opt in ('-f', '--fileset'):
            fileset = arg

    assert concordance
    assert fileset

    init_fileset(fileset)
    parse_csv(concordance)
    end_fileset(fileset)


if __name__ == '__main__':
    main(sys.argv[1:])
