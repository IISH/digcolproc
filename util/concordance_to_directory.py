#!/usr/bin/env python
#
# concordance_to_directory.py
import os
import csv
import sys
import getopt
import shutil
import os.path

from droid import Droid
from exceptions import ValueError


def usage():
    print('Usage: concordance_to_directory.py ' +
          '--concordance [concordance file] --droid [droid file] --fileset [file set] --access [default access]')


def init_fileset(fileset):
    fileset = os.path.normpath(fileset)
    if not os.path.exists(fileset):
        print('The file set ' + fileset + ' was not found!')
        exit(1)
    os.chdir(fileset)

    if not os.path.exists(os.path.join(fileset, 'tmp')):
        os.mkdir('tmp')
    os.chdir(os.path.join(fileset, 'tmp'))


def parse_csv(concordance, droid, access):
    columns = {}
    with open(concordance, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for i, items in enumerate(reader):
            if i == 0:
                columns = identify_columns(items)
            else:
                move_files(columns, items, droid, access)


def identify_columns(items):
    columns = {'text': {}}
    for i, val in enumerate(items):
        if val.startswith('text'):
            columns['text'][val] = i
        else:
            columns[val] = i
    return columns


def move_files(columns, items, droid, access):
    archive_id = os.path.basename(os.path.dirname(os.getcwd()))
    dir_name = archive_id + '.' + items[columns['objnr']]
    volgnr = items[columns['volgnr']]

    use = determine_use_for(items[columns['master']], droid)

    move_files_for(dir_name, items[columns['master']], use, volgnr)

    if 'jpeg' in columns:
        move_files_for(dir_name, items[columns['jpeg']], use + '/.level1', volgnr)

    for name in columns['text']:
        move_files_for(dir_name, items[columns['text'][name]], name, volgnr)

    determine_access_for(dir_name, items[columns['master']], access)


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


def determine_use_for(file_path, droid):
    if file_path.startswith('/'):
        file_path = file_path[1:]
    parent_path = os.path.dirname(os.path.dirname(os.getcwd()))
    file_path = os.path.join(parent_path, os.path.normpath(file_path))

    with open(droid, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for file in reader:
            if file[Droid.FILE_PATH].strip() == file_path:
                mime_type = file[Droid.MIME_TYPE]
                type = mime_type.split('/')[0]

                if type == 'image':
                    return 'archive image'

                if type == 'audio':
                    return 'archive audio'

                if type == 'video':
                    return 'archive video'

                if mime_type == 'application/pdf' or mime_type == 'application/x-pdf':
                    return 'pdf'

    raise ValueError('Unknown content type found for file ' + file_path)


def determine_access_for(parent_dir, cur_master_path, default):
    new_access_path = os.path.join(parent_dir, '.access.txt')
    if not os.path.isfile(new_access_path):
        if cur_master_path.startswith('/'):
            cur_master_path = cur_master_path[1:]
        parent_path = os.path.dirname(os.path.dirname(os.getcwd()))
        cur_master_path = os.path.join(parent_path, os.path.normpath(cur_master_path))
        cur_access_dir = os.path.dirname(cur_master_path)
        cur_access_path = os.path.join(cur_access_dir, '.access.txt')

        if os.path.isfile(cur_access_path):
            os.rename(cur_access_path, new_access_path)
        else:
            file = open(new_access_path, 'w')
            file.write(default)
            file.close()


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
    concordance = droid = fileset = access = 0

    try:
        opts, args = getopt.getopt(argv, 'c:d:f:a:hd',
                                   ['concordance=', 'droid=', 'fileset=', 'access=', 'help', 'debug'])
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
        elif opt in ('-d', '--droid'):
            droid = arg
        elif opt in ('-f', '--fileset'):
            fileset = arg
        elif opt in ('-a', '--access'):
            access = arg

    assert concordance
    assert droid
    assert fileset
    assert access

    init_fileset(fileset)
    parse_csv(concordance, droid, access)
    end_fileset(fileset)


if __name__ == '__main__':
    main(sys.argv[1:])
