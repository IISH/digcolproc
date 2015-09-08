#!/usr/bin/env python
#
# instruction_droid_to_mets.py
#
# Reads in a SOR instruction and a CSV Droid report and parses it to a METS document.

from droid import Droid
import re
import sys
import csv
import getopt

from os.path import normpath, split
from xml.etree import ElementTree

from urllib2 import urlopen  # Python 3.2 : urllib.request
from xml.sax.saxutils import XMLGenerator

_attributes = {u'xmlns': 'http://www.loc.gov/METS/',
               u'xmlns:xlink': 'http://www.w3.org/1999/xlink',
               'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
               'xsi:schemaLocation': 'http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/mets.xsd'}


class MetsDocument:
    def __init__(self, output, encoding='utf-8', short_empty_elements=True):
        """
        Set up a document object, which takes SAX events and outputs
        an XML log file
        """
        document = XMLGenerator(output, encoding)  # Python 3.2 : short_empty_elements
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


class FileRef:
    id = checkSum = mimeType = size = pid = level = seq = textLayer = language = master_use = None


class FileGrp:
    def __init__(self):
        self.id = self.use = None
        self.file_refs = []
        self.attributes = {}


DERIVATIVES_USES = {
    'archive image': {
        'level1': 'hires reference image',
        'level2': 'reference image',
        'level3': 'thumbnail image'
    },
    'archive audio': {
        'level1': 'reference audio'
    },
    'archive video': {
        'level1': 'reference video',
        'level2': 'stills video',
        'level3': 'thumbnail video',
    }
}


# For now specifically aimed at access only!
def create_amdsec(xl, file_groups, access='closed'):
    xl.elem('amdSec', {'ID': 'admSec-1'}). \
        elem('rightsMD', {'ID': 'rightsMD-1'}). \
        elem('mdWrap', {'MDTYPE': 'OTHER', 'OTHERMDTYPE': 'EPDCX'}). \
        elem('xmlData'). \
        elem('epdcx:descriptionSet', {'xmlns:epdcx': 'http://purl.org/eprint/epdcx/2006-11-16/',
                                      'xsi:schemaLocation': 'http://purl.org/eprint/epdcx/2006-11-16/ '
                                                            'http://purl.org/eprint/epdcx/xsd/2006-11-16/epdcx.xsd'})

    for file_group in file_groups:
        open_access = False
        file_ref = file_group.file_refs[0]

        if file_ref.textLayer:
            open_access = access == 'open'  # If level 1 has open access, then text layers also have open access
        elif access == 'open':
            open_access = file_ref.level != 'master'
        elif access == 'restricted':
            open_access = file_ref.level == 'level3' or file_ref.level == 'level2'
        elif access == 'minimal':
            open_access = file_ref.level == 'level3'
        elif access == 'closed':
            open_access = False

        value_ref = 'http://purl.org/eprint/accessRights/OpenAccess' \
            if open_access \
            else 'http://purl.org/eprint/accessRights/ClosedAccess'

        xl.elem('epdcx:description', {'epdcx:resourceId': file_group.id})
        xl.elem('epdcx:statement', {'epdcx:propertyURI': 'http://purl.org/dc/terms/available',
                                    'epdcx:valueRef': value_ref})
        xl.close_entry(2)

    xl.close_entry(5)


# For now specifically aimed at languages only!
def create_dmdsec(xl, file_groups):
    languages = {}
    id_counter = 1

    for file_group in file_groups:
        file_ref = file_group.file_refs[0]
        language = file_ref.language

        if language:
            if language in languages:
                file_group.attributes['DMDID'] = languages[language]
            else:
                id = 'dmdSec-' + str(id_counter)
                id_counter += 1

                languages[language] = id
                file_group.attributes['DMDID'] = id
                xl.elem('dmdSec', {'ID': id}). \
                    elem('mdWrap', {'MIMETYPE': 'text/xml', 'MDTYPE': 'DC'}). \
                    elem('xmlData'). \
                    elem('dc:metadata', {'xmlns:dc': 'http://purl.org/dc/elements/1.1/'}). \
                    elem('dc:language', characters=language). \
                    close_entry(5)

    return xl


def create_filesec(xl, file_groups):
    xl.elem('fileSec')
    for file_group in file_groups:
        xl.elem('fileGrp', dict({'ID': file_group.id, 'USE': file_group.use}, **file_group.attributes))
        for file_ref in file_group.file_refs:
            link = 'http://hdl.handle.net/' + file_ref.pid + '?locatt=view:' + file_ref.level
            file = xl.elem('file', {'CHECKSUM': file_ref.checkSum,
                                    'CHECKSUMTYPE': 'MD5',
                                    'ID': file_ref.id,
                                    'MIMETYPE': file_ref.mimeType,
                                    'SIZE': file_ref.size})
            file.elem('FLocat', {'LOCTYPE': 'HANDLE',
                                 'xlink:href': link,
                                 'xlink:type': 'simple'})
            file.close_entry(2)
        xl.close_entry()
    xl.close_entry()
    return xl


def create_structmap_physical(xl, file_refs):
    xl.elem('structMap', {'ID': 'physical'}).elem('div')

    seq_nr = 0
    found_files = []
    while seq_nr == 0 or found_files:
        seq_nr += 1
        found_files = []

        for file_ref in file_refs:
            if seq_nr == int(file_ref.seq):
                found_files.append(file_ref.id)

        if found_files:
            xl.elem('div', {'LABEL': 'Page ' + str(seq_nr), 'ORDER': str(seq_nr), 'TYPE': 'page'})
            for id in found_files:
                xl.elem('fptr', {'FILEID': id}).close_entry()
            xl.close_entry()

    xl.close_entry(2)
    return xl


def get_file_groups(file_refs):
    id_counter = 1
    file_groups = []

    # Make another list of file refs to keep track of whether there are still file refs left to add to file groups
    file_refs_left = [file_ref for file_ref in file_refs]

    # As long as there are file refs yet to add... continue...
    while file_refs_left:
        first_file_ref = file_refs_left[0]

        # Determine the current file group to create by the first found file ref
        if first_file_ref.textLayer:
            format_text = 'plain' if first_file_ref.mimeType == 'text/plain' else 'alto'
            use = first_file_ref.textLayer + ' ' + format_text + ' text'
            group_file_refs = [file_ref for file_ref in file_refs_left
                               if file_ref.textLayer == first_file_ref.textLayer
                               and file_ref.mimeType == first_file_ref.mimeType
                               and file_ref.language == first_file_ref.language]
        else:
            level = first_file_ref.level
            use = first_file_ref.master_use

            group_file_refs = [file_ref for file_ref in file_refs_left
                               if file_ref.level == level and file_ref.master_use == use and not file_ref.textLayer]

            # Determine the use attribute of a derivative based on the master use and the derivative level
            if level != 'master':
                if use in DERIVATIVES_USES and level in DERIVATIVES_USES[use]:
                    use = DERIVATIVES_USES[use][level]
                else:
                    print('Unknown derivative found for a ' + level + ' derivative ' +
                          'with master use ' + use + ' and with PID ' + first_file_ref.pid)
                    exit(1)

        file_group = FileGrp()
        file_group.id = 'fileGrp-' + str(id_counter)
        file_group.use = use
        file_group.file_refs = group_file_refs

        file_groups.append(file_group)
        id_counter += 1

        # Remove all file refs we added to this group from the list of file refs yet to group
        file_refs_left = [file_ref for file_ref in file_refs_left if file_ref not in group_file_refs]

    return file_groups


def get_file_refs(instruction, droid):
    pids = get_pids(instruction)
    folders = get_folders(droid)

    id_counter = 1
    file_refs = []
    with open(droid, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        next(reader, None)  # skip the headers
        for file in reader:
            if file[Droid.PID] in pids:
                file_ref = FileRef()
                file_ref.id = 'f' + str(id_counter)
                file_ref.checkSum = file[Droid.HASH]
                file_ref.mimeType = file[Droid.MIME_TYPE]
                file_ref.size = file[Droid.SIZE]
                file_ref.pid = file[Droid.PID]
                file_ref.level = 'master'
                file_ref.seq = file[Droid.SEQ]
                file_ref.master_use = folders[file[Droid.PARENT_ID]]

                # Use the folder pattern 'text [text_layer] [language]' to determine text layers
                file_path = normpath(file[Droid.FILE_PATH])
                head, tail = split(file_path)
                while head and tail:
                    if tail.startswith('text '):
                        # Language is not always specified, so make sure it is None in that case
                        text, text_layer, language = tail.split() + (3 - len(tail.split())) * [None]
                        file_ref.textLayer = text_layer
                        file_ref.language = language
                    head, tail = split(head)

                file_refs.append(file_ref)
                id_counter += 1

                if not file_ref.textLayer:  # Text layers don't have derivatives, so skip
                    id_counter = add_derivatives_for_master(file_ref, file_refs, id_counter)

    return file_refs


def add_derivatives_for_master(master_file_ref, file_refs, id_counter):
    url = 'http://disseminate.objectrepository.org/metadata/' + master_file_ref.pid + '?accept=text/xml&format=xml'
    metadata_xml = urlopen(url)
    metadata_xml = re.sub('xmlns="[^"]+"', '', metadata_xml, count=1)  # Remove the namespace for simpler findall()

    metadata = ElementTree.fromstring(metadata_xml)
    file_elems = metadata.findall('.//orfile//pidurl/..')  # Find all elements with a PID URL
    file_elems = list(set(file_elems) - set(metadata.findall('.//orfile/pidurl/..')))  # Remove the main PID URL
    file_elems = list(set(file_elems) - set(metadata.findall('.//orfile/master')))  # Remove the master PID URL

    for file_elem in file_elems:
        file_ref = FileRef()
        file_ref.id = 'f' + str(id_counter)
        file_ref.checkSum = file_elem.find('md5').text
        file_ref.mimeType = file_elem.find('contentType').text
        file_ref.size = file_elem.find('length').text
        file_ref.pid = master_file_ref.pid
        file_ref.level = file_elem.tag
        file_ref.seq = master_file_ref.seq
        file_ref.master_use = master_file_ref.master_use

        file_refs.append(file_ref)
        id_counter += 1

    return id_counter


def get_folders(droid):
    folders = {}
    with open(droid, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        next(reader, None)  # skip the headers

        for file in reader:
            if file[Droid.TYPE] == 'Folder':
                folders[file[Droid.ID]] = file[Droid.NAME]
                # print(file[Droid.ID] + ' = ' + file[Droid.NAME])

    return folders


def get_pids(instruction):
    with open(instruction, 'r') as f:
        instruction_xml = f.read()
        instruction_xml = re.sub('xmlns="[^"]+"', '', instruction_xml, count=1)  # Remove the namespace

        instruction_elems = ElementTree.fromstring(instruction_xml)
        pids = [stagingfile_elem.find('pid').text for stagingfile_elem in instruction_elems.findall('.//stagingfile')]

    return pids


def parse_csv(instruction, droid, targetfile, access):
    file_refs = get_file_refs(instruction, droid)
    file_groups = get_file_groups(file_refs)

    manifest = open(targetfile, 'w')
    xl = MetsDocument(manifest)

    xl.elem(u'mets', _attributes)
    create_amdsec(xl, file_groups, access)
    create_dmdsec(xl, file_groups)
    create_filesec(xl, file_groups)
    create_structmap_physical(xl, file_refs)

    xl.close_entry().close()
    return


def usage():
    print('Usage: instruction_droid_to_mets.py -i Instruction used during ingest -d Droid CSV file '
          '-t Target METS document -objid objid -access Access level')


def main(argv):
    instruction = droid = targetfile = objid = access = 0
    try:
        opts, args = getopt.getopt(argv, 'i:d:t:o:a:h', ['instruction=', 'droid=', 'targetfile=',
                                                         'objid=', 'access=', 'help'])
    except getopt.GetoptError:
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-i', '--instruction'):
            instruction = arg
        elif opt in ('-d', '--droid'):
            droid = arg
        elif opt in ('-t', '--targetfile'):
            targetfile = arg
        elif opt in ('-o', '--objid'):
            objid = arg
        elif opt in ('-a', '--access'):
            access = arg

    assert instruction
    assert droid
    assert targetfile
    assert objid
    assert access in ['closed', 'restricted', 'minimal', 'open']

    print('instruction=' + instruction)
    print('droid=' + droid)
    print('targetfile=' + targetfile)
    print('objid=' + objid)
    print('access=' + access)

    _attributes['OBJID'] = objid
    parse_csv(instruction, droid, targetfile, access)
    return


if __name__ == '__main__':
    main(sys.argv[1:])
