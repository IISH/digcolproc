#!/usr/bin/env python#
#
# Returns the status of an instruction. E.g.
# <instruction xmlns="http://objectrepository.org/instruction/1.0/" access="irsh" action="upsert" autoGeneratePIDs="none" autoIngestValidInstruction="true" contentType="application/octet-stream" embargoAccess="closed" fileSet="/mnt/sa/10622/23457/N10681364" na="10622" notificationEMail="edr@iisg.nl" objid="10622/N10681364" pdfLevel="level2" pidwebserviceEndpoint="https://pid.socialhistoryservices.org/secure" replaceExistingDerivatives="true" resolverBaseUrl="http://hdl.handle.net/" task="org.objectrepository.instruction.Task : null" id="57d676030cf26a179451c78a" plan="StagingfileIngestMaster">
# <workflow>
# <identifier>9171d931-4c1c-4416-8b1a-1b1b048325db</identifier>
# <name>InstructionIngest</name>
# <statusCode>900</statusCode>
# </workflow>
# </instruction>

import getopt
import sys
import xml.sax


class InstructionHandler(xml.sax.handler.ContentHandler):
    bookmark = None
    statusCode = None
    name = None

    def startElement(self, name, attrs):
        self.bookmark = name

    def characters(self, content):
        if content.strip():
            if self.bookmark == 'statusCode':
                self.statusCode = content
            elif self.bookmark == 'name':
                self.name = content

    def status(self):
        return '{}{}'.format(self.name, self.statusCode)


def usage():
    print('Usage: instruction_status.py --pid [pid] --token [SOR access token]')


def main(argv):
    url = None

    try:
        opts, args = getopt.getopt(argv, 'hu:',['help', 'url='])
    except getopt.GetoptError as e:
        print("Opt error: " + e.msg)
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-u', '--url'):
            url = arg
        else:
            print("Illegal argument: " + opt)
            sys.exit(1)

    assert url

    try:
        handler = InstructionHandler()
        xml.sax.parse(url, handler)
    except:
        sys.exit(1)

    status = handler.status()
    if status:
        print(status)
    else:
        sys.exit(1)


if __name__ == '__main__':
    main(sys.argv[1:])


