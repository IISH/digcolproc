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
from exceptions import ValueError, OSError


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


def parse_csv(fileset, concordance, droid, access):
    columns = {}
    with open(concordance, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for i, items in enumerate(reader):
            if i == 0:
                columns = identify_columns(items)
            else:
                move_files(columns, items, fileset, droid, access)


def identify_columns(items):
    columns = {'text': {}}
    for i, val in enumerate(items):
        if val.startswith('text'):
            columns['text'][val] = i
        else:
            columns[val] = i
    return columns


def move_files(columns, items, fileset, droid, access):
    parent_dir, archive_id = os.path.split(fileset)
    new_dir_name = archive_id + '.' + items[columns['objnr']]
    volgnr = items[columns['volgnr']]
    new_dir_path = archive_id + os.path.sep + 'tmp' + os.path.sep + new_dir_name

    use = None
    if items[columns['master']] or 'level1' in columns:
        level1 = items[columns['level1']] if 'level1' in columns else ''
        use = determine_use_for(parent_dir, items[columns['master']], level1, droid)

    if use:
        if items[columns['master']]:
            new_file_path = new_dir_path + os.path.sep + use
            move_files_for(parent_dir, archive_id, items[columns['master']], new_file_path, volgnr)

        if 'level1' in columns:
            new_file_path = new_dir_path + os.path.sep + use + os.path.sep + '.level1'
            move_files_for(parent_dir, archive_id, items[columns['level1']], new_file_path, volgnr)

    for name in columns['text']:
        new_file_path = new_dir_path + os.path.sep + name
        move_files_for(parent_dir, archive_id, items[columns['text'][name]], new_file_path, volgnr)

    new_file_path = new_dir_path + os.path.sep + '.access.txt'
    determine_access_for(parent_dir, items[columns['master']], new_file_path, access)


def move_files_for(parent_dir, archive_id, cur_file_path, new_file_path, volgnr):
    if cur_file_path:
        full_cur_file_path = get_full_path(parent_dir, cur_file_path)
        if os.path.exists(full_cur_file_path):
            full_new_file_path = os.path.join(parent_dir, new_file_path)
            new_filename = archive_id + '.' + volgnr + os.path.splitext(full_cur_file_path)[1]

            try:
                os.makedirs(full_new_file_path)  # Python 3.2 : exist_ok=True
            except OSError:
                if not os.path.isdir(full_new_file_path):
                    raise

            os.rename(full_cur_file_path, os.path.join(full_new_file_path, new_filename))


def determine_use_for(parent_dir, file_path_master, file_path_level1, droid):
    full_path_master = get_full_path(parent_dir, file_path_master)
    full_path_level1 = get_full_path(parent_dir, file_path_level1)

    with open(droid, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for file in reader:
            path = file[Droid.FILE_PATH].strip()
            if path == full_path_master or path == full_path_level1:
                mime_type = file[Droid.MIME_TYPE]
                type = mime_type.split('/')[0]

                if type == 'image':
                    return 'archive image'

                if type == 'audio':
                    return 'archive audio'

                if type == 'video':
                    return 'archive video'

                if mime_type == 'application/pdf' or mime_type == 'application/x-pdf':
                    return 'archive pdf'

    raise ValueError('Unknown content type found for file ' + file_path_master + ' or file ' + file_path_level1)


def determine_access_for(parent_dir, cur_file_path, new_access_file, default):
    new_access_path = os.path.join(parent_dir, new_access_file)
    if not os.path.isfile(new_access_path):
        full_cur_file_path = get_full_path(parent_dir, cur_file_path)
        cur_access_dir = os.path.dirname(full_cur_file_path)
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


def get_full_path(parent_dir, file_path):
    if file_path.startswith('/'):
        file_path = file_path[1:]
    return os.path.normpath(os.path.join(parent_dir, file_path))


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
    parse_csv(fileset, concordance, droid, access)
    end_fileset(fileset)


if __name__ == '__main__':
    main(sys.argv[1:])
