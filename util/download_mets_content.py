#!/usr/bin/env python
#
# download_mets_content.py




# !/usr/bin/env python

import getopt
import urllib
import os
import sys
import xml.sax


class MetsHandler(xml.sax.handler.ContentHandler):
    token = None
    mets_filesec_filegrp_id = None
    mets_filesec_filegrp_file_checksum = None

    def __init__(self, token):
        self.token = token

    def startElement(self, name, attrs):
        if name == 'fileGrp':
            self.mets_filesec_filegrp_id = attrs['ID']
        if name == 'file':
            self.mets_filesec_filegrp_file_checksum = attrs['CHECKSUM']
        if name == 'FLocat':
            url = attrs['xlink:href'] + '&urlappend=%3Faccess_token%3D' + self.token
            file_name = attrs['xlink:title']
            self.download_file(url, file_name)

    #def characters(self, content):
    #     Do something

    def download_file(self, url, file_name):
        if not os.path.exists(self.mets_filesec_filegrp_id):
            os.mkdir(self.mets_filesec_filegrp_id)
        file = self.mets_filesec_filegrp_id + os.sep + file_name
        urllib.urlretrieve(url, file)

        file_checksum = file + '.md5'
        text_file = open(file_checksum, 'w')
        text_file.write( self.mets_filesec_filegrp_file_checksum + '  ' + file_name)
        text_file.close()


def usage():
    print('Usage: download_mets_content.py --pid [pid] --token [SOR access token]')


def main(argv):
    pid = token = None

    try:
        opts, args = getopt.getopt(argv, 'hpt:', ['help', 'pid=', 'token='])
    except getopt.GetoptError as e:
        print("Opt error: " + e.msg)
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        if opt in ('-p', '--pid'):
            pid = arg
        if opt in ('-t', '--token'):
            token = arg

    assert pid
    assert token

    url = 'http://disseminate.objectrepository.org/mets/' + pid + '?access_token=' + token
    handler = MetsHandler(token)

    try:
        xml.sax.parse(url, handler)
    except:
        print(sys.exc_info()[0])
        sys.exit(1)

if __name__ == '__main__':
    main(sys.argv[1:])
