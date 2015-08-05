#!/usr/bin/env python
#
# droid_to_mets.py
#
# Reads in a csv droid report and parses it to an METS document.

from droid import Droid
import sys
import csv
import getopt
from xml.sax.saxutils import XMLGenerator

_attributes = {u'xmlns:METS': 'http://www.loc.gov/METS/',
               u'xmlns:xlink': 'http://www.w3.org/1999/xlink',
               'xmlns:dcterms': 'http://purl.org/dc/terms/',
               'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
               'xsi:schemaLocation': 'http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/mets.xsd http://purl.org/dc/terms/ http://dublincore.org/schemas/xmls/qdc/2008/02/11/dcterms.xsd'}


class MetsDocument:
    def __init__(self, output, encoding='utf-8', short_empty_elements=True):
        """
        Set up a document object, which takes SAX events and outputs
        an XML log file
        """
        document = XMLGenerator(output, encoding)
        document.startDocument()
        self._document = document
        self._output = output
        self._encoding = encoding
        self._short_empty_elements = short_empty_elements
        self._open_elements = []
        return

    def close(self):
        """
        Clean up the logger object
        """
        self._document.endDocument()
        self._output.close()
        return

    def elem(self, element, attributes=None, characters=None):
        if not attributes:
            attributes = {}
        self._open_elements.append(element)
        self._document.startElement(element, attributes)
        if characters is not None:
            self._document.characters(characters)
        return self

    def close_entry(self, elements=1):
        for i in range(elements):
            element = self._open_elements.pop()
            self._document.endElement(element)
        return self


def dmdsec(xl, dmd_sec_id, text, loctype='HANDLE', mimetype='application/xml', mdtype='EAD',
           label='Collection Finding Aid'):
    xl.elem('METS:dmdSec', {'ID': dmd_sec_id}). \
        elem('METS:mdRef', {'LOCTYPE': loctype, 'MIMETYPE': mimetype, 'MDTYPE': mdtype, 'LABEL': label}, text). \
        close_entry(2)
    return


def amdsec(xl, amd_sec_id='admSec-1', rights_md='rightsMD-1', access='closed'):
    xl.elem('METS:amdSec', {'ID': amd_sec_id}). \
        elem('METS:rightsMD', {'ID': rights_md}). \
        elem('METS:mdWrap', {'MDTYPE': 'OTHER', 'OTHERMDTYPE': 'EPDCX'}). \
        elem('METS:xmlData'). \
        elem('epdcx:descriptionSet')
    if access == 'closed':
        xl.elem(u'epdcx:statement', {'epdcx:propertyURI': 'http://purl.org/dc/terms/available',
                                     'epdcx:valueRef': 'http://purl.org/eprint/accessRights/ClosedAccess'}, access)
    else:
        print("Fatal. Unsupported access status")
        sys.exit(1)
    xl.close_entry(6)


def fileMD(xl, id, title, date):
    return xl.elem('METS:file', {'ID': id, 'MIMETYPE': 'text/xml'}). \
        elem('METS:FContent'). \
        elem('METS:xmlData'). \
        elem('dcterms:title', None, title).close_entry(). \
        elem('dcterms:created', None, date + 'Z').close_entry(). \
        elem('dcterms:accessRights', None, 'closed').close_entry(). \
        close_entry(3)


# Create a fileSet. We will follow the same arrangement as in the Fedora example at
# http://www.paradigm.ac.uk/workbook/ingest/fedora-diringest.html
def create_filesec(xl, csvfile):
    xl.elem('METS:fileSec')
    with open(csvfile, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        next(reader, None)  # skip the headers
        for file in reader:
            id = file[Droid.TYPE].upper() + '_' + file[Droid.ID]
            id_dc = file[Droid.TYPE].upper() + '_DC_' + file[Droid.ID]
            name = file[Droid.NAME]
            if file[Droid.TYPE] == 'Folder':
                xl.elem('METS:fileGrp')
                fileMD(xl, id_dc, name, file[Droid.LAST_MODIFIED]).close_entry()
            else:  # We have two fileGrp elements here. We can insert more metadata in future.
                xl.elem('METS:fileGrp').elem('METS:fileGrp')
                mimetype = file[Droid.MIME_TYPE].split(',')[0].strip()
                fileMD(xl, id_dc, name, file[Droid.LAST_MODIFIED]).elem('METS:file', {'CHECKSUM': file[Droid.HASH],
                                                                                      'CHECKSUMTYPE': 'MD5', 'ID': id,
                                                                                      'MIMETYPE': mimetype,
                                                                                      'SIZE': file[Droid.SIZE]}).elem(
                    'METS:FLocat', {'LOCTYPE': 'HANDLE',
                                    'xlink:href': 'http://hdl.handle.net/' + file[Droid.PID] + '?locatt=view:master',
                                    'xlink:type': 'simple'}).close_entry(4)
    csvfile.close()
    xl.close_entry()
    return xl


# Create a structMap. We will follow the same arrangement as in the Fedora example at
# http://www.paradigm.ac.uk/workbook/ingest/fedora-diringest.html
# The CSV will not be that large... 1GB top, so we assume we can read it in memory.
def structmap(xl, files, map):
    for file in files:
        id = file[Droid.ID]
        fileid_content = file[Droid.TYPE].upper() + '_' + id
        fileid_dc = file[Droid.TYPE].upper() + '_DC_' + id
        if file[Droid.TYPE] == 'Folder':
            xl.elem('METS:div', {'TYPE': 'folder'}). \
                elem('METS:div', {'TYPE': 'dc'}). \
                elem('METS:fptr', {'FILEID': fileid_dc}).close_entry(2)
            if id in map:
                structmap(xl, map[id], map)
            xl.close_entry()
        else:
            _a = {'TYPE': 'file'}
            if ( file[Droid.SEQ] ):
                _a['ORDER'] = file[Droid.SEQ]
            xl.elem('METS:div', _a). \
                elem('METS:div', {'TYPE': 'content'}). \
                elem('METS:fptr', {'FILEID': fileid_content}). \
                close_entry(2). \
                elem('METS:div', {'TYPE': 'dc'}). \
                elem('METS:fptr', {'FILEID': fileid_dc}). \
                close_entry(3)
    return xl


def create_structmap(xl, csvfile):
    structural_map = {}
    with open(csvfile, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        next(reader, None)  # skip the headers
        for file in reader:
            parent_id = file[Droid.PARENT_ID]
            if parent_id:
                if parent_id in structural_map:
                    structural_map[parent_id].append(file)
                else:
                    structural_map[parent_id] = [file]
            else:
                structural_map[0] = [file]

    csvfile.close()

    xl.elem('METS:structMap', {'ID': 'physical'})
    structmap(xl, structural_map[0], structural_map)
    xl.close_entry()

    return xl


def parse_csv(sourcefile, targetfile):
    manifest = open(targetfile, 'wb')
    xl = MetsDocument(manifest)

    xl.elem(u'METS:mets', _attributes)
    create_filesec(xl, sourcefile)
    create_structmap(xl, sourcefile)

    xl.close_entry()
    xl.close()
    return


def usage():
    print('Usage: droid_to_mets.py -objid OBJID -s droid file.csv -t mets document')


def main(argv):
    sourcefile = objid = targetfile = 0

    try:
        opts, args = getopt.getopt(argv, 'o:s:t:a:h', ['objid=', 'sourcefile=', 'targetfile=', 'help'])
    except getopt.GetoptError:
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-s', '--sourcefile'):
            sourcefile = arg
        elif opt in ('-t', '--targetfile'):
            targetfile = arg
        elif opt in ('-o', '--objid'):
            objid = arg

    assert sourcefile
    assert targetfile
    assert objid

    print('sourcefile=' + sourcefile)
    print('targetfile=' + targetfile)
    print('objid=' + objid)

    _attributes['OBJID'] = objid
    parse_csv(sourcefile, targetfile)
    return


if __name__ == '__main__':
    main(sys.argv[1:])