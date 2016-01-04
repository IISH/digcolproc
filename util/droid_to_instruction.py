#!/usr/bin/env python
#
# droid_to_instruction.py
#
# Reads in a csv document and parses it to an XML SOR processing instruction.

import csv
from droid import Droid
import getopt
import re
import sys
from xml.sax.saxutils import XMLGenerator
from os.path import normpath, split


_attributes = {u'xmlns': 'http://objectrepository.org/instruction/1.0/'}
PID_PATTERN = re.compile('^[0-9]+\/.*$')


class XmlInstruction:
    def __init__(self, output, encoding='utf-8'):
        """
        Set up a document object, which takes SAX events and outputs
        an XML log file
        """
        document = XMLGenerator(output, encoding)
        document.startDocument()
        self._document = document
        self._output = output
        return

    def close(self):
        """
        Clean up the logger object
        """
        self._document.endDocument()
        self._output.close()
        return

    def open_entry(self, element, attributes=None):
        if not attributes: attributes = {}
        self._document.startElement(element, attributes)
        return

    def close_entry(self, element):
        self._document.endElement(element)
        return

    def write_entry(self, element, value):
        self.open_entry(element)
        self._document.characters(value)
        self.close_entry(element)
        return


def parse_csv(text_layer_check):
    sourcefile = _attributes.get('sourcefile')
    targetfile = _attributes.get('targetfile')

    text_layer_access = 'irsh' if _attributes.get('access') == 'open' else 'closed'

    manifest = open(targetfile, 'wb')
    xl = XmlInstruction(manifest)

    xl.open_entry(u'instruction', _attributes)

    with open(sourcefile, 'rb') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for items in reader:
            if items[Droid.TYPE] == 'File' or items[Droid.TYPE] == 'Container':
                xl.open_entry(u'stagingfile')

                # Use the folder pattern 'text ' to determine text layers, which have a slightly different access state
                if text_layer_check:
                    file_path = normpath(items[Droid.FILE_PATH])
                    head, tail = split(file_path)
                    while head and tail:
                        if tail.startswith('text '):
                            xl.write_entry(u'access', text_layer_access)
                        head, tail = split(head)

                assert PID_PATTERN.match(items[Droid.PID])
                xl.write_entry(u'pid', items[Droid.PID])
                xl.write_entry(u'location', items[Droid.FILE_PATH])
                xl.write_entry(u'contentType', items[Droid.MIME_TYPE])
                xl.write_entry(u'md5', items[Droid.HASH])
                if items[Droid.SEQ]:
                    xl.write_entry(u'seq', items[Droid.SEQ])
                xl.close_entry(u'stagingfile')

    xl.close_entry(u'instruction')
    xl.close()
    return


def usage():
    print('Usage: droid_to_instruction.py --objid OBJID --textLayerCheck -s droid file.csv -t instruction')


def main(argv):
    text_layer_check = False

    try:
        opts, args = getopt.getopt(argv, 's:t:h',
                                   ['help', 'textLayerCheck', 'objid=', 'access=', 'submission_date=',
                                    'autoIngestValidInstruction=', 'label=', 'action=', 'notificationEMail=', 'plan='])
    except getopt.GetoptError as e:
        print("Opt error: " + e.msg)
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        if opt in ('-s'):
            _attributes['sourcefile'] = arg
        elif opt in ('-t'):
            _attributes['targetfile'] = arg
        elif opt in ('--textLayerCheck'):
            text_layer_check = True

        if opt.startswith('--') and not opt == '--textLayerCheck':
            _attributes[opt[2:]] = arg

    assert _attributes.get('sourcefile')
    assert _attributes.get('targetfile')
    assert _attributes.get('objid')
    assert _attributes.get('access')
    assert _attributes.get('plan')

    parse_csv(text_layer_check)
    return


if __name__ == '__main__':
    main(sys.argv[1:])