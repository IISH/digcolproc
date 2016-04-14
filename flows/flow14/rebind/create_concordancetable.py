#!/usr/bin/env python
#
# create_concordancetable.py
#
# Read in a XML file
# Run a xpath query
# And pipe out the result.


import sys
import getopt
from lxml import etree


def parse_ead(xml_file, xsl_file, result_file):
    dom = etree.parse(xml_file)
    xslt = etree.parse(xsl_file)
    transform = etree.XSLT(xslt)
    result = transform(dom)
    f = open(result_file, 'w')
    f.write(etree.tostring(result, pretty_print=True))
    f.close()


def usage():
    print('Usage: create_concordancetable.py -f|--file=[XML file] -d|--debug')


def main(argv):

    xml_file = xsl_file = result_file = None

    try:
        opts, args = getopt.getopt(argv, 'h',
                                   ['xml_file=', 'xsl_file=', 'result_file=', 'help'])
    except getopt.GetoptError:
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in '--result_file':
            result_file = arg
        elif opt in '--xml_file':
            xml_file = arg
        elif opt in '--xsl_file':
            xsl_file = arg

    assert result_file
    assert xml_file
    assert xsl_file
    print('result_file=' + result_file)
    print('xml_file=' + xml_file)
    print('xsl_file=' + xsl_file)

    parse_ead(xml_file, xsl_file, result_file)


if __name__ == '__main__':
    main(sys.argv[1:])
