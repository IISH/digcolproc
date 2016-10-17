#!/usr/bin/env python
#
# xslt_transformer.py
#
# Read in a XML file
# Apply the xslt
# And pipe out the result.


import sys
import getopt
from lxml import etree


def parse_ead(xml_file, xsl_file, result_file, parameters):
    xsl_tree = etree.parse(xsl_file)
    transform = etree.XSLT(xsl_tree)
    result = transform(etree.parse(xml_file))
    if result_file:
        f = open(result_file, 'w')
        f.write(str(result))
        f.close()
    else:
        sys.stdout.write(str(result))

def usage():
    print('Usage: xslt_transformer.py --xml_file=[source XML file] --xsl_file=[stylesheet] --result_file=[output file] --param_name value')


def main(argv):

    xml_file = xsl_file = result_file = verbose = None
    parameters = {}

    try:
        opts, args = getopt.getopt(argv, 'h',
                                   ['xml_file=', 'xsl_file=', 'result_file=', 'help', 'verbose'])
    except getopt.GetoptError:
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in '--result_file':
            result_file = arg
        elif opt in '--verbose':
            verbose = True
        elif opt in '--xml_file':
            xml_file = arg
        elif opt in '--xsl_file':
            xsl_file = arg
        else:
            if opt.startswith('--'):
                parameters[opt.substring(2)] = arg
            else:
                parameters[opt.substring(1)] = arg

    assert xml_file
    assert xsl_file
    if verbose:
        if result_file:
            print('result_file=' + result_file)
        print('xml_file=' + xml_file)
        print('xsl_file=' + xsl_file)
        print('parameters=')
        print(parameters)

    parse_ead(xml_file, xsl_file, result_file, parameters)


if __name__ == '__main__':
    main(sys.argv[1:])
