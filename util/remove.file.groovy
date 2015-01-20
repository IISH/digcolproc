import javax.xml.stream.XMLInputFactory
import javax.xml.stream.XMLStreamReader


def arguments = [:]
for (int i = 0; i < args.length; i++) {
    if (args[i][0] == '-') {
        arguments.put(args[i].substring(1), args[i + 1])
    }
}

assert arguments.or, "Expect -or argument: base url of the object repository"
assert arguments.file, "Expect -file argument: full path of the instruction file"
//assert arguments.access_token, "Expect -access_token argument: object repository webservice key"

println("Arguments: " + arguments)

File instruction = new File(arguments.file)
assert instruction.exists()

def good = []
def bad = []
readInstruction(instruction, good, bad, arguments)

if (!bad && !good)
    println('No files.')

println(bad.size + " mislukt:")
bad.each {
    println(it)
}

println();

println(good.size + " gelukt:")
good.each {
    println(it)
}

def readInstruction(File instruction, def good, def bad, def arguments) {

    final String stagingfile = "stagingfile"
    final XMLInputFactory xif = XMLInputFactory.newInstance()
    final XMLStreamReader xsr = xif.createXMLStreamReader(instruction.newReader())
    while (xsr.hasNext()) {
        int next = xsr?.next()

        if (next == XMLStreamReader.START_ELEMENT && xsr.localName.contains(stagingfile)) {
            // example <pid>10622/12345</pid><location>/2013-02-12/30051/30000000000000.tif</location><contentType>text/plain</contentType><md5>b0fcc7b9968168c4e31b90ebceb52932</md5>


            def l = [:]
            while (xsr.hasNext() && !(xsr.next() == XMLStreamReader.END_ELEMENT && xsr.localName.contains(stagingfile))) {
                if (xsr.startElement) {
                    String name = xsr.getLocalName()
                    l.put(name, xsr.getElementText())
                }
            }

            if (inSor(l, arguments)) {
                if (Boolean.parseBoolean(arguments.delete))
                    new File(instruction.parentFile.parentFile, l.location).delete()
                String urlAppend = (arguments.access_token) ? "&urlappend=%3Faccess_token%3D" + arguments.access_token : ""
                good << "http://hdl.handle.net/$l.pid?locatt=view:level2" + urlAppend
            } else {
                bad << "$l.pid not in the object repository."
            }
        }
    }
}

/**
 * inSor
 *
 * Check availability, the md5 and the access status
 *
 * @param l
 * @param arguments
 * @return
 */
def inSor(def l, def arguments) {

    String url = "${arguments.or}/metadata/$l.pid?accept=text/xml&format=xml"
    def xml = null
    try {
        xml = new XmlSlurper().parse(url)
    } catch (Exception e) {
        println(e)
    }

    def md5 = xml?.'**'?.find { it.name() == 'md5' }?.text()
    compare(md5, l.md5)
}

boolean compare(String md5_A, String md5_B) {

    if (md5_A == null || md5_B == null) return false

    final BigInteger md5_alfa
    final BigInteger md5_beta

    try {
        md5_alfa = new BigInteger(md5_A, 16)
        md5_beta = new BigInteger(md5_B, 16)
    } catch (NumberFormatException e) {
        println(e.message)
        return false
    }

    md5_beta.compareTo(md5_alfa) == 0
}