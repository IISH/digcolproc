#!/usr/bin/env python
#
# report_image_quality.py
#
# Make a report based on a supplied CSV table.
# The csv must be of the form: "TCN Value","Call Number Label","Barcode"
# The report will create a new CSV with an extra column, containing the status of the image quality:
# [filename]-image-quality.csv: "TCN Value","Call Number Label","Barcode", "content type", "length", "resolveUrl", "x-resolution", "y-resolution", "width", "height"
# The quality is none, low and high.

import sys
import csv
import getopt
import xml.sax


# Column description of the report
class Columns:
    TCN_VALUE = 0
    CALL_NUMBER_LABEL = 1
    BARCODE = 2


class Report(xml.sax.handler.ContentHandler):
    bookmark = content_type = length = resolve_url = x_resolution = y_resolution = width = height = None
    file_csv = 'report-data.csv'
    na = '12345'
    record = False
    url = 'http://localhost'

    def __init__(self, file_csv, na, url):
        self.file_csv = file_csv
        self.na = na
        self.url = url

    def parse_csv(self):

        file_target = self.file_csv + '-image-quality.csv'
        h = open(file_target, 'w')

        with open(self.file_csv, 'rb') as file:
            reader = csv.reader(file, delimiter=',', quotechar='"')
            for items in reader:

                if items[Columns.TCN_VALUE] == 'TCN Value':  # Header
                    items.append('CONTENT_TYPE')
                    items.append('LENGTH')
                    items.append('RESOLVE_URL')
                    items.append('X-RESOLUTION')
                    items.append('Y-RESOLUTION')
                    items.append('WIDTH')
                    items.append('HEIGHT')
                else:
                    barcode = items[Columns.BARCODE]
                    self.status(barcode)
                    items.append(self.content_type)
                    items.append(self.length)
                    items.append(self.resolve_url)
                    items.append(self.x_resolution)
                    items.append(self.y_resolution)
                    items.append(self.width)
                    items.append(self.height)

                items = ['"{0}"'.format(item.replace('"', '""')) for item in
                         items]  # Add the double quotes and ensure the values with double quotes are escaped.
                h.write(','.join(items) + "\n")
        h.close()

    def status(self, barcode):
        barcode = self.normalize(barcode)
        self.content_type = self.length = self.resolve_url = self.x_resolution = self.y_resolution = self.width \
            = self.height = ''
        url = self.url + '/metadata/' + barcode + '?accept=xml'
        try:
            xml.sax.parse(url, self)
        except:
            print(sys.exc_info()[0])

    # Add the na if not there
    def normalize(self, barcode):
        prefix = self.na + '/'
        if barcode.startswith(prefix):
            return barcode
        else:
            return prefix + barcode

    def startElement(self, name, attrs):
        self.bookmark = name
        if self.record and name == 'content':
            self.x_resolution = self.v('x-resolution', attrs)
            self.y_resolution = self.v('y-resolution', attrs)
            self.width = self.v('width', attrs)
            self.height = self.v('height', attrs)
        elif name == 'master':
            self.record = True
        elif name in ['level', 'level2', 'level3']:
            self.record = False

    def characters(self, content):
        if self.record:
            if self.bookmark == 'length':
                self.length = content
            elif self.bookmark == 'contentType':
                self.content_type = content
            elif self.bookmark == 'resolveUrl':
                self.resolve_url = content

    def v(self, key, attrs, default=''):
        if key in attrs:
            return attrs[key]
        else:
            return default


def usage():
    print('Usage: report_image_quality.py -f [source csv file] -n [naming authority] -u [endpoint disseminate]')


def main(argv):
    file_csv = url = na = None

    try:
        opts, args = getopt.getopt(argv, 'f:u:n:h',
                                   ['file=', 'url=', 'na=', 'help'])
    except getopt.GetoptError:
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-f', '--file'):
            file_csv = arg
        elif opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-n', '--na'):
            na = arg
        elif opt in ('-u', '--url'):
            url = arg

    assert file_csv
    assert na
    assert url

    print 'file_csv=' + file_csv
    print 'na=' + na
    print 'url=' + url

    report = Report(file_csv, na, url)
    report.parse_csv()


if __name__ == '__main__':
    main(sys.argv[1:])
