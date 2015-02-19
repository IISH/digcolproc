#!/usr/bin/env python
#
# droid_to_instruction.py
#
# Reads in a csv document and parses it to an XML SOR processing instruction.

from droid import Droid
import sys
import csv
import getopt
from xml.sax.saxutils import XMLGenerator

_attributes = {u'xmlns': 'http://objectrepository.org/instruction/1.0/'}


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
        self._encoding = encoding
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


def parse_csv():
    sourcefile = _attributes.get('sourcefile')
    targetfile = _attributes.get('targetfile')

    manifest = open(targetfile, 'wb')
    xl = XmlInstruction(manifest)

    xl.open_entry(u'instruction', _attributes)

    with open(sourcefile, 'rb') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for items in reader:
            if items[Droid.TYPE] == 'File':
                xl.open_entry(u'stagingfile')
                xl.write_entry(u'pid', items[Droid.PID])
                xl.write_entry(u'location', items[Droid.FILE_PATH])
                xl.write_entry(u'contentType', items[Droid.MIME_TYPE])
                xl.write_entry(u'md5', items[Droid.HASH])
                xl.close_entry(u'stagingfile')

    xl.close()
    return


def usage():
    print('Usage: droid_to_instruction.py --objid OBJID -s droid file.csv -t instruction')


def main(argv):
    try:
        opts, args = getopt.getopt(argv, 's:t:h',
                                   ['help', 'objid=', 'access=', 'submission_date=', 'autoIngestValidInstruction=',
                                    'label=', 'action=', 'notificationEMail=', 'plan='])
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

        if opt.startswith('--'):
            _attributes[opt[2:]] = arg

    assert _attributes.get('sourcefile')
    assert _attributes.get('targetfile')
    assert _attributes.get('objid')
    assert _attributes.get('access')
    assert _attributes.get('plan')

    parse_csv()
    return


if __name__ == '__main__':
    main(sys.argv[1:])