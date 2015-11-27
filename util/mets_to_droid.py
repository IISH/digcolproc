#!/usr/bin/env python
#
# mets_to_droid.py
#

import re
import sys
import getopt

from xml.etree import ElementTree


MASTER_HANDLE_REGEX = re.compile('^http://hdl.handle.net/(.*)\?locatt=view:master$')
METS_NS = {'mets': 'http://www.loc.gov/METS/', 'xlink': 'http://www.w3.org/1999/xlink'}


class FileRef:
    id = checkSum = mimeType = size = pid = seq = masterUse = None


def mets_to_droid(droid, mets):
    files = parse_mets(mets)
    append_files(files, droid)


def parse_mets(mets):
    files = []

    mets_xml = open(mets).read()
    mets_tree = ElementTree.fromstring(mets_xml)

    for file_group in mets_tree.findall('.//mets:fileSec//mets:fileGrp', METS_NS):
        use = file_group.get('USE')

        for file in file_group.findall('mets:file', METS_NS):
            flocat = file.find('mets:FLocat', METS_NS)
            link = flocat.get('{' + METS_NS['xlink'] + '}href')
            pid_result = MASTER_HANDLE_REGEX.search(link)

            if pid_result:
                file_ref = FileRef()
                file_ref.id = file.get('ID')
                file_ref.checkSum = file.get('CHECKSUM')
                file_ref.mimeType = file.get('MIMETYPE')
                file_ref.size = file.get('SIZE')
                file_ref.pid = pid_result.group(1)
                file_ref.masterUse = use

                files.append(file_ref)

    for div in mets_tree.findall(".//mets:structMap[@TYPE='physical']//mets:div[@TYPE='page']", METS_NS):
        seq = div.get('ORDER')

        for fptr in div.findall('mets:fptr', METS_NS):
            file_id = fptr.get('FILEID')

            for file_ref in files:
                if file_ref.id == file_id:
                    file_ref.seq = seq

    return files


def append_files(files, droid):
    folders = {}
    manifest = open(droid, 'a')

    count = 1
    for file_ref in files:
        master_use = file_ref.masterUse
        if master_use.endswith('text'):
            master_use = 'text ' + master_use.partition(' ')[0]

        if not master_use in folders:
            folders[master_use] = 'fake' + str(count)
            count += 1

            manifest.write('"' + folders[master_use] + '","","./' + master_use + '/",' +
                           '"./' + master_use + '/","' + master_use + '",,"Done","","Folder",' +
                           ',"","false","","","","","","","",""' + "\n")

        id = 'fake' + str(count)
        count += 1
        manifest.write('"' + id + '","' + folders[master_use] + '","","","","Signature",' +
                       '"Done","' + file_ref.size + '","File","","","false","' + file_ref.checkSum + '","1",' +
                       '"","' + file_ref.mimeType + '","","","' + file_ref.pid + '","' + file_ref.seq + '"' + "\n")

    manifest.close()


def usage():
    print('Usage: mets_to_droid.py -d droid report -m original mets')


def main(argv):
    droid = mets = 0

    try:
        opts, args = getopt.getopt(argv, 'd:m', ['droid=', 'mets='])
    except getopt.GetoptError:
        usage()
        sys.exit(2)

    for opt, arg in opts:
        if opt in ('-d', '--droid'):
            droid = arg
        elif opt in ('-m', '--mets'):
            mets = arg

    assert droid
    assert mets

    print('droid=' + droid)
    print('mets=' + mets + '\n')

    mets_to_droid(droid, mets)


if __name__ == '__main__':
    main(sys.argv[1:])
