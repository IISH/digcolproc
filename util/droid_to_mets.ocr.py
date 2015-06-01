#!/usr/bin/env python
#
# droid_to_mets.py
#
# Reads in a csv droid report and parses it to an METS document.

from droid import Droid
import re
import sys
import csv
import time
import getopt
import os.path

from xml.etree import ElementTree
from urllib.request import urlopen
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


class Derivative:
    pidurl = None
    resolveUrl = None
    contentType = None
    length = None
    md5 = None
    uploadDate = None


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


def fileMD(xl, id, title=None, date=None):
    xl = xl.elem('METS:file', {'ID': id, 'MIMETYPE': 'text/xml'}). \
        elem('METS:FContent'). \
        elem('METS:xmlData')
    xl = xl.elem('dcterms:title', None, title).close_entry() if title else xl
    xl = xl.elem('dcterms:created', None, date + 'Z').close_entry() if date else xl
    xl = xl.elem('dcterms:accessRights', None, 'closed').close_entry()
    return xl.close_entry(3)


# Create a fileSet. We will follow the same arrangement as in the Fedora example at
# http://www.paradigm.ac.uk/workbook/ingest/fedora-diringest.html
def create_filesec(xl, csvfile, derivatives_for_pids):
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
                xl = add_file(xl, id, id_dc, hash=file[Droid.HASH], mimetype=file[Droid.MIME_TYPE],
                              size=file[Droid.SIZE], pid=file[Droid.PID], level='master', name=name,
                              date=file[Droid.LAST_MODIFIED])

    for pid in derivatives_for_pids:
        id, levels_for_derivatives = derivatives_for_pids[pid]
        for level in levels_for_derivatives:
            derivative = levels_for_derivatives[level]
            id_file = 'FILE_' + level.upper() + '_' + str(id)
            id_dc = 'FILE_DC_' + level.upper() + '_' + str(id)
            xl = add_file(xl, id_file, id_dc, hash=derivative.md5, mimetype=derivative.contentType,
                          size=derivative.length, pid=pid, level=level, date=derivative.uploadDate)

    xl.close_entry()
    return xl


def add_file(xl, id, id_dc, hash, mimetype, size, pid, level, name=None, date=None):
    xl.elem('METS:fileGrp').elem('METS:fileGrp')
    file_md = fileMD(xl, id_dc, name, date)
    file_md.elem('METS:file', {'CHECKSUM': hash,
                               'CHECKSUMTYPE': 'MD5',
                               'ID': id,
                               'MIMETYPE': mimetype,
                               'SIZE': size})
    file_md.elem('METS:FLocat', {'LOCTYPE': 'HANDLE',
                                 'xlink:href': 'http://hdl.handle.net/' + pid + '?locatt=view:' + level,
                                 'xlink:type': 'simple'})
    file_md.close_entry(4)

    return xl


# Create a structMap. We will follow the same arrangement as in the Fedora example at
# http://www.paradigm.ac.uk/workbook/ingest/fedora-diringest.html
# The CSV will not be that large... 1GB top, so we assume we can read it in memory.
def structmap_physical(xl, files, map):
    for file in files:
        id = file[Droid.ID]
        fileid_content = file[Droid.TYPE].upper() + '_' + id
        fileid_dc = file[Droid.TYPE].upper() + '_DC_' + id
        if file[Droid.TYPE] == 'Folder':
            xl.elem('METS:div', {'TYPE': 'folder'}). \
                elem('METS:div', {'TYPE': 'dc'}). \
                elem('METS:fptr', {'FILEID': fileid_dc}).close_entry(2)
            if id in map:
                structmap_physical(xl, map[id], map)
            xl.close_entry()
        else:
            add_file_div(xl, fileid_content, fileid_dc, {'ORDER': file[Droid.SEQ]} if (file[Droid.SEQ]) else {})

    return xl


def structmap_logical(xl, groups, derivatives_for_pids):
    xl.elem('METS:div')
    for filename in groups:
        files = groups[filename]

        seq_nr = files[0][Droid.SEQ]
        xl.elem('METS:div', {'LABEL': 'Page ' + seq_nr, 'ORDER': seq_nr, 'TYPE': 'page'})

        for file in files:
            id = file[Droid.ID]
            fileid_content = file[Droid.TYPE].upper() + '_' + id
            fileid_dc = file[Droid.TYPE].upper() + '_DC_' + id
            add_file_div(xl, fileid_content, fileid_dc)

        for pid in derivatives_for_pids:
            if pid == file[Droid.PID]:
                id, levels_for_derivatives = derivatives_for_pids[pid]
                for level in levels_for_derivatives:
                    fileid_content = 'FILE_' + level.upper() + '_' + str(id)
                    fileid_dc = 'FILE_DC_' + level.upper() + '_' + str(id)
                    add_file_div(xl, fileid_content, fileid_dc)

        xl.close_entry()
    xl.close_entry()
    return xl


def add_file_div(xl, fileid_content, fileid_dc, div_attr={}):
    xl.elem('METS:div', dict({'TYPE': 'file'}, **div_attr)). \
        elem('METS:div', {'TYPE': 'content'}). \
        elem('METS:fptr', {'FILEID': fileid_content}). \
        close_entry(2). \
        elem('METS:div', {'TYPE': 'dc'}). \
        elem('METS:fptr', {'FILEID': fileid_dc}). \
        close_entry(3)
    return xl


def create_structmap_physical(xl, csvfile):
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

    xl.elem('METS:structMap', {'ID': 'physical'})
    structmap_physical(xl, structural_map[0], structural_map)
    xl.close_entry()

    return xl


def create_structmap_logical(xl, csvfile, derivatives_for_pids):
    structural_map = {}
    with open(csvfile, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        next(reader, None)  # skip the headers
        for file in reader:
            if file[Droid.TYPE] == 'File' and file[Droid.SEQ]:
                filename = os.path.splitext(file[Droid.NAME])[0]
                if filename in structural_map:
                    structural_map[filename].append(file)
                else:
                    structural_map[filename] = [file]

    if structural_map:
        xl.elem('METS:structMap', {'ID': 'logical'})
        structmap_logical(xl, structural_map, derivatives_for_pids)
        xl.close_entry()

    return xl


def obtain_derivatives(instruction):
    with open(instruction, 'r') as f:
        instruction_xml = f.read()
        instruction_xml = re.sub('xmlns="[^"]+"', '', instruction_xml, count=1)  # Remove the namespace

        instruction_elems = ElementTree.fromstring(instruction_xml)
        pids = [pid_elem.text for pid_elem in instruction_elems.findall('.//pid')]

    return get_derivatives_for_pids(pids)


def get_derivatives_for_pids(pids):
    derivatives_per_pid = {}
    for i, pid in enumerate(pids):
        url = 'http://disseminate.objectrepository.org/metadata/' + pid + '?accept=xml'
        metadata_xml = urlopen(url)
        metadata_xml = re.sub('xmlns="[^"]+"', '', metadata_xml, count=1)  # Remove the namespace for simpler findall()

        metadata = ElementTree.fromstring(metadata_xml)
        file_elems = metadata.findall('.//orfile//pidurl/..')  # Find all elements with a PID URL
        file_elems = list(set(file_elems) - set(metadata.findall('.//orfile/pidurl/..')))  # Remove the main PID URL
        file_elems = list(set(file_elems) - set(metadata.findall('.//orfile/master')))  # Remove the master PID URL

        derivatives = {}
        for file_elem in file_elems:
            derivative = Derivative()
            derivative.pidurl = file_elem.find('pidurl').text
            derivative.resolveUrl = file_elem.find('resolveUrl').text
            derivative.contentType = file_elem.find('contentType').text
            derivative.length = file_elem.find('length').text
            derivative.md5 = file_elem.find('md5').text
            date_time = time.strptime(file_elem.find('uploadDate').text, "%a %b %d %H:%M:%S CEST %Y")
            derivative.uploadDate = time.strftime('%Y-%m-%dT%H:%m:%S', date_time)

            derivatives[file_elem.tag] = derivative

        if derivatives:
            derivatives_per_pid[pid] = (i, derivatives)

    return derivatives_per_pid


def parse_csv(sourcefile, targetfile, instruction):
    derivatives_for_pids = {}
    if instruction:
        derivatives_for_pids = obtain_derivatives(instruction)

    manifest = open(targetfile, 'wb')
    xl = MetsDocument(manifest)

    xl.elem(u'METS:mets', _attributes)
    create_filesec(xl, sourcefile, derivatives_for_pids)
    create_structmap_physical(xl, sourcefile)
    create_structmap_logical(xl, sourcefile, derivatives_for_pids)

    xl.close_entry()
    xl.close()
    return


def usage():
    print('Usage: droid_to_mets.py -objid OBJID -s droid file.csv -t mets document' +
          '-i instruction used during ingest (optional / post ingest)')


def main(argv):
    instruction = sourcefile = objid = targetfile = 0
    try:
        opts, args = getopt.getopt(argv, 'o:s:t:i:h', ['objid=', 'sourcefile=', 'targetfile=', 'instruction=', 'help'])
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
        elif opt in ('-i', '--instruction'):
            instruction = arg

    assert sourcefile
    assert targetfile
    assert objid

    print('sourcefile=' + sourcefile)
    print('targetfile=' + targetfile)
    print('objid=' + objid)
    print('instruction=' + instruction)

    _attributes['OBJID'] = objid
    parse_csv(sourcefile, targetfile, instruction)
    return


if __name__ == '__main__':
    main(sys.argv[1:])