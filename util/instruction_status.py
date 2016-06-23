#!/usr/bin/env python

import getopt
import sys
import xml.sax


class InstructionHandler(xml.sax.handler.ContentHandler):
    found_elem = False
    status_code = None

    def startElement(self, name, attrs):
        self.found_elem = name == 'statusCode'

    def characters(self, content):
        if self.found_elem:
            self.found_elem = False
            self.status_code = content

    def statusCode(self):
        return self.status_code


def usage():
    print('Usage: instruction_status.py --pid [pid] --token [SOR access token]')


def main(argv):
    pid = token = None

    try:
        opts, args = getopt.getopt(argv, 'hpt:',['help', 'pid=', 'token='])
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

    try:
        url = 'http://disseminate.objectrepository.org/10622/instruction/status?pid=' + pid + '&access_token=' + token
        handler = InstructionHandler()
        xml.sax.parse(url, handler)
    except:
        sys.exit(1)

    status_code = handler.statusCode()
    if status_code:
        print(status_code)
    else:
        sys.exit(1)


if __name__ == '__main__':
    main(sys.argv[1:])


