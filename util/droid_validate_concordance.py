#!/usr/bin/env python
#
# droid_validate_concordance.py
#

import re
import sys
import csv
import getopt

from droid import Droid
from os.path import normpath, basename, splitext, split, sep

# Required
OBJECT_COLUMN_NAME = 'objnr'
INV_COLUMN_NAME = 'ID'
VOLGNR_COLUMN_NAME = 'volgnr'
TIFF_COLUMN_NAME = 'master'

REQUIRED_COLUMNS = [OBJECT_COLUMN_NAME, INV_COLUMN_NAME, VOLGNR_COLUMN_NAME, TIFF_COLUMN_NAME]

# Optional
JPEG_COLUMN_NAME = 'jpeg'

OPTIONAL_COLUMNS = [JPEG_COLUMN_NAME]

# Text (starts with)
TEXT_COLUMN_NAME = 'text'

FILE_NAME_REGEX = re.compile('^[\sa-zA-Z0-9-:\._\(\)\[\]\{@\$\}=\\\]{1,240}$')


class ExpectedNr:
    expected_seq_nr = 1
    expected_obj_nr = None


errors_found = False


def parse_csv(basepath, droid, concordance):
    files = []
    all_items = []
    header_columns = {}
    expected_nr = ExpectedNr()

    # Perform validation for each line in the concordance table
    with open(concordance, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for i, items in enumerate(reader):
            if not header_columns:
                print('Validating header columns')

                identify_columns(items, header_columns)
            else:
                print('Validating column ' + str(i))

                # Perform validation for the current item in the concordance table
                expected_nr = check_sequence_numbers(items, i, header_columns, expected_nr)
                test_relationships(items, i, header_columns)
                test_file_name(items, i, header_columns, all_items)
                test_file_existence_and_headers(items, i, header_columns, droid, basepath)

                print('Validated column ' + str(i))
                update_files(items, header_columns, files)

            all_items.append(items)

    # Perform validation for the complete concordance table
    print('Comparing files on disk with files in concordance table')
    test_droid_existence(all_items, header_columns, droid, basepath, int(expected_nr.expected_obj_nr), files)
    print('Compared files on disk with files in concordance table')

    global errors_found
    if errors_found:
        print('----  Errors found!  ----' + '\n')
        exit(1)
    else:
        print('----  All tests passed.  ----' + '\n')


def identify_columns(items, header_columns):
    header_columns[TEXT_COLUMN_NAME] = {}
    
    for i, val in enumerate(items):
        for column_name in REQUIRED_COLUMNS:
            if val == column_name:
                header_columns[column_name] = i
        for column_name in OPTIONAL_COLUMNS:
            if val == column_name:
                header_columns[column_name] = i
        if val.startswith(TEXT_COLUMN_NAME):
            header_text_columns = header_columns[TEXT_COLUMN_NAME]
            header_text_columns[val] = i

    for column_name in REQUIRED_COLUMNS:
        if column_name not in header_columns:
            error('The mandatory column \'' + column_name + '\' is missing in the concordance table.')
            exit(1)

    print('Parsing columns complete. No errors detected.')


def check_sequence_numbers(items, line, header_columns, expected_nr):
    obj_nr = items[header_columns[OBJECT_COLUMN_NAME]]
    seq_nr = items[header_columns[VOLGNR_COLUMN_NAME]]

    try:
        seq_nr_int = int(seq_nr)

        # Update the expected numbers if we start recounting with a new object number
        expected_obj_nr = expected_nr.expected_obj_nr
        if expected_obj_nr is None or obj_nr.lower() != expected_obj_nr.lower():
            expected_nr.expected_obj_nr = obj_nr
            expected_nr.expected_seq_nr = 1

        if seq_nr_int != expected_nr.expected_seq_nr:
            error('Volgnummer \'' + seq_nr + '\' incorrect. ' +
                  'Expected: ' + str(expected_nr.expected_seq_nr), line, items)

        expected_nr.expected_seq_nr = seq_nr_int + 1
    except ValueError:
        error('Incorrect entry \'' + seq_nr + '\' in volgnummer column', line, items)

    return expected_nr


def test_relationships(items, line, header_columns):
    def execute_for_column(column_name, column):
        if column_name is not TIFF_COLUMN_NAME:
            org_tiff_name = items[header_columns[TIFF_COLUMN_NAME]]
            org_reference_name = column

            tiff_name = splitext(basename(normpath(org_tiff_name)))[0]
            reference_name = splitext(basename(normpath(org_reference_name)))[0]

            if tiff_name != reference_name:
                if not org_reference_name:
                    error('Empty file name found in column ' + column_name, line, items)
                else:
                    error('Difference in filenames between ' + tiff_name + ' and ' + reference_name, line, items)

    for_all_columns_with_items(header_columns, items, execute_for_column)


def test_file_name(items, i, header_columns, all_items):
    tiff = items[header_columns[TIFF_COLUMN_NAME]]
    inv = items[header_columns[INV_COLUMN_NAME]]

    for cur_items in all_items[1:]:
        if cur_items[header_columns[TIFF_COLUMN_NAME]] == tiff:
            error('Duplicate file entry \'' + tiff + '\'', i, items)

    tiff_file = basename(normpath(tiff))
    if FILE_NAME_REGEX.match(tiff_file) is None:
        error('The filename \'' + tiff_file + '\' contains an invalid character.', i, items)

    if FILE_NAME_REGEX.match(inv) is None:
        error('The inventory number \'' + inv + '\' contains an invalid character.', i, items)


def test_file_existence_and_headers(items, line, header_columns, droid, basepath):
    objnr = items[header_columns[OBJECT_COLUMN_NAME]]

    def execute_for_column(column_name, path):
        valid_signatures = []
        if column_name == TIFF_COLUMN_NAME:
            valid_signatures = ['fmt/353']
        elif column_name == JPEG_COLUMN_NAME:
            valid_signatures = ['fmt/41', 'fmt/42', 'fmt/43', 'fmt/44']
        elif column_name in header_columns[TEXT_COLUMN_NAME]:
            valid_signatures = ['x-fmt/14', 'x-fmt/15', 'x-fmt/16', 'x-fmt/111']  # Plain text
            valid_signatures += ['fmt/101']  # XML

        found_file = False
        found_objnr = False

        file_path = join_paths(basepath, path)
        objnr_path = join_paths(basepath, get_parent_directory_of_file(path), objnr)

        with open(droid, 'r') as csvfile:
            reader = csv.reader(csvfile, delimiter=',', quotechar='"')
            next(reader, None)  # skip the headers
            for file in reader:
                droid_file_path = file[Droid.FILE_PATH].strip()

                if droid_file_path == file_path:
                    found_file = True

                    if file[Droid.PUID] not in valid_signatures:
                        error('The file ' + file_path + ' does not have the correct signature.', line, items)

                    # Text related files can be smaller than 1000 bytes
                    if column_name in header_columns[TEXT_COLUMN_NAME]:
                        if int(file[Droid.SIZE]) == 0:
                            error('The file ' + file_path + ' is empty.', line, items)
                    elif int(file[Droid.SIZE]) < 1000:
                        error('The file ' + file_path + ' has size smaller than limit of 1000 bytes.', line, items)

                if droid_file_path == objnr_path:
                    found_objnr = True

        if path and not found_file:
            error('File entry in concordance table does not exist in directory: ' + file_path, line, items)

        if path and not found_objnr:
            error('Found objectnummer ' + objnr + ' in concordance table without corresponding subdirectory '
                  + objnr_path, line, items)

    for_all_columns_with_items(header_columns, items, execute_for_column)


def update_files(items, header_columns, files):
    def execute_for_column(column_name, column):
        file = basename(normpath(column))
        files.append(file)

    for_all_columns_with_items(header_columns, items, execute_for_column)


def test_droid_existence(all_items, header_columns, droid, basepath, objnr_count, files):
    def execute_for_column(column_name, parent_directory):
        identifier = -1
        folder_ids = []
        folder_names = []
        file_names = []
        path_parent = join_paths(basepath, parent_directory)

        with open(droid, 'r') as csvfile:
            reader = csv.reader(csvfile, delimiter=',', quotechar='"')

            # First find the id
            next(reader, None)  # skip the headers
            for file in reader:
                droid_file_path = file[Droid.FILE_PATH].strip()
                if droid_file_path == path_parent:
                    identifier = int(file[Droid.ID])

        if identifier > 0:
            with open(droid, 'r') as csvfile:
                reader = csv.reader(csvfile, delimiter=',', quotechar='"')

                # Next find the folders
                next(reader, None)  # skip the headers
                for file in reader:
                    if file[Droid.PARENT_ID] and int(file[Droid.PARENT_ID]) == identifier \
                            and file[Droid.TYPE].strip() == 'Folder':
                        folder_ids.append(int(file[Droid.ID]))
                        folder_names.append(file[Droid.NAME].strip())

            with open(droid, 'r') as csvfile:
                reader = csv.reader(csvfile, delimiter=',', quotechar='"')

                # Lastly find all the files
                next(reader, None)  # skip the headers
                for file in reader:
                    if file[Droid.PARENT_ID] and int(file[Droid.PARENT_ID]) in folder_ids:
                        file_names.append(file[Droid.NAME].strip())

        if objnr_count != len(folder_names) and column_name not in header_columns[TEXT_COLUMN_NAME]:
            error_str = 'Amount of directories found in ' + path_parent + ' (' + str(len(folder_ids)) + ') ' + \
                        'is not the same as the amount of objects found in concordance file ' + \
                        '(' + str(objnr_count) + ')\n'
            missing_folders = ['Folder: ' + missing_folder for missing_folder
                               in set(folder_names) - set(range(1, objnr_count))]
            error(error_str + '\n'.join(missing_folders))

        missing_files = set(file_names) - set(files)
        if len(missing_files) > 0:
            error_str = 'The following files are found on disk but are not listed in the concordance table: \n'
            error(error_str + '\n'.join(missing_files))

    for_all_columns(header_columns, all_items, execute_for_column)


def for_all_columns_with_items(header_columns, items, exec_for_column):
    column = items[header_columns[TIFF_COLUMN_NAME]]
    exec_for_column(TIFF_COLUMN_NAME, normpath(column) if column else '')

    if JPEG_COLUMN_NAME in header_columns:
        column = items[header_columns[JPEG_COLUMN_NAME]]
        exec_for_column(JPEG_COLUMN_NAME, normpath(column) if column else '')

    if TEXT_COLUMN_NAME in header_columns:
        header_text_columns = header_columns[TEXT_COLUMN_NAME]
        for column_name in header_text_columns:
            column = items[header_text_columns[column_name]]
            # Textual files are optional, so skip if empty
            if column:
                exec_for_column(column_name, normpath(column) if column else '')


def for_all_columns(header_columns, all_items, exec_for_column):
    parent_directory = find_parent_folder_for_column(header_columns, TIFF_COLUMN_NAME, all_items) \
        if all_items else None
    if parent_directory:
        exec_for_column(TIFF_COLUMN_NAME, parent_directory)

    if JPEG_COLUMN_NAME in header_columns:
        parent_directory = find_parent_folder_for_column(header_columns, JPEG_COLUMN_NAME, all_items) \
            if all_items else None
        if parent_directory:
            exec_for_column(JPEG_COLUMN_NAME, parent_directory)

    if TEXT_COLUMN_NAME in header_columns:
        header_text_columns = header_columns[TEXT_COLUMN_NAME]
        for column_name in header_text_columns:
            parent_directory = find_parent_folder_for_column(header_text_columns, column_name, all_items) \
                if all_items else None
            if parent_directory:
                exec_for_column(column_name, parent_directory)


def find_parent_folder_for_column(header_columns, column_name, all_items):
    for item in all_items[1:]:
        if item[header_columns[column_name]]:
            parent_folder = get_parent_directory_of_file(item[header_columns[column_name]])
            return normpath(parent_folder)
    return None


def get_parent_directory_of_file(path):
    # Remove (1) the file name and (2) its directory from the path: so split twice
    return split(split(path)[0])[0]


def join_paths(*paths):
    paths = [normpath(path) for path in paths]
    path = sep.join(paths)
    return normpath(path)


def error(message, line=None, items=None):
    global errors_found
    errors_found = True

    print('Error: ' + message)
    if line is not None and items is not None:
        print('line ' + str(line + 1) + ': ' + ','.join(items))


def usage():
    print('Usage: droid_validate_concordance.py -b base path; -d droid report; -c concordance table')


def main(argv):
    basepath = droid = concordance = 0

    try:
        opts, args = getopt.getopt(argv, 'b:d:c:hd', ['basepath=', 'droid=', 'concordance=', 'help', 'debug'])
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
        elif opt in ('-b', '--basepath'):
            basepath = arg
        elif opt in ('-d', '--droid'):
            droid = arg
        elif opt in ('-c', '--concordance'):
            concordance = arg

    assert basepath
    assert droid
    assert concordance

    print('basepath=' + basepath)
    print('droid=' + droid)
    print('concordance=' + concordance + '\n')

    parse_csv(basepath, droid, concordance)


if __name__ == '__main__':
    main(sys.argv[1:])
