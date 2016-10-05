#!/usr/bin/env python
#
# download_mets_content.py


import getopt
import sys
from xml.etree import ElementTree as ET


class MetsParser():
    METS_NS = {'METS': 'http://www.loc.gov/METS/', 'xlink': 'http://www.w3.org/1999/xlink',
               'dcterms': 'http://purl.org/dc/terms/'}
    mets_tree = None

    def __init__(self, file):
        self.mets_tree = ET.parse(file).getroot()

    def run(self):
        print '"TYPE", "TITLE", "MD5"'
        xpath = "METS:structMap[@ID='physical']/METS:div"
        self.div(self.mets_tree.findall(xpath, self.METS_NS), '')

    def div(self, divs, parent):
        for div in divs:
            type = div.get('TYPE')
            if type == 'folder':
                fileid = self.findId(div, 'dc')
                title = self.findTitle(fileid)
                folder = parent + '/' + title
                items = ['"{0}"'.format(item.encode('utf-8').replace('"', '""')) for item in ['D', folder, '']]  # Escape our quotes.
                print(','.join(items))
                self.div(div.findall('METS:div', self.METS_NS), parent + '/' + title)
            if type == 'file':
                fileid = self.findId(div, 'dc')
                title = self.findTitle(fileid)
                fileid = self.findId(div, 'content')
                md5 = self.findMD5(fileid)
                items = ['"{0}"'.format(item.encode('utf-8').replace('"', '""')) for item in ['F', parent + '/' + title, md5]]
                print(','.join(items))

    def findId(self, div, type):
        xpath = "METS:div[@TYPE='{}']/METS:fptr".format(type)
        fptr = div.find(xpath, self.METS_NS)
        assert fptr is not None
        fileid = fptr.get('FILEID')
        assert fileid
        return fileid.strip()

    def findTitle(self, fileid):
        xpath = "METS:fileSec/METS:fileGrp//METS:file[@ID='{}']/METS:FContent/METS:xmlData/dcterms:title".format(fileid)
        title = self.mets_tree.find(xpath, self.METS_NS)
        assert title is not None
        assert title.text
        return title.text.strip()

    def findMD5(self, fileid):
        xpath = "METS:fileSec/METS:fileGrp//METS:file[@ID='{}']".format(fileid)
        file = self.mets_tree.find(xpath, self.METS_NS)
        assert file is not None
        md5 = file.get('CHECKSUM')
        assert md5
        return md5.strip().zfill(32)


def usage():
    print('Usage: download_mets_content.py --file [file to mets document]')


def main(argv):
    file = None

    try:
        opts, args = getopt.getopt(argv, 'f:h', ['file=', 'help'])
    except getopt.GetoptError as e:
        print("Opt error: " + e.msg)
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-f', '--file'):
            file = arg
        else:
            print("Unknown argument: " + opt)
            sys.exit(1)

    assert file
    metsParser = MetsParser(file)
    metsParser.run()


if __name__ == '__main__':
    main(sys.argv[1:])
