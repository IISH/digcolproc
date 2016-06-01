import groovy.xml.StreamingMarkupBuilder
import org.xml.sax.SAXException

import java.security.MessageDigest

/**
 * SorInstruction
 *
 * Creates a OR instruction for the submission package.
 *
 * The procedure iterates recursively through the fileset;
 * For each file the md5 sum is calculated.
 * The extension of the file is compared to the mimeRepository table and the probably content type is retrieved.
 *
 */

class SorInstruction {

    private def orAttributes
    def files = 0
    private def mimeRepository = [:]
    private MessageDigest digest = MessageDigest.getInstance("MD5")
    private boolean recurse = false
    private static access_stati = ['open', 'restricted', 'closed', 'irsh']
    private static String ACCESS_DEFAULT = 'closed'

    public SorInstruction(def args) {
        orAttributes = args
        println("Loaded instruction class with arguments:")
        println(orAttributes)
        recurse = (Boolean.parseBoolean(orAttributes.recurse))

        def file = new File(System.getenv("FLOWS_HOME"), "src/main/global/contenttype.txt")
        assert file.exists()
        file.eachLine {
            final String[] split = it.split(",")
            if (!mimeRepository.containsKey(split[0])) mimeRepository.put(split[0], split[1])
        }
    }

    void start() {

        def file = new File(orAttributes.fileSet, "instruction.xml")
        def writer = file.newWriter('UTF-8')
        def builder = new StreamingMarkupBuilder()
        builder.setEncoding("utf-8")
        builder.setUseDoubleQuotes(true)

        writer << builder.bind {
            mkp.xmlDeclaration()
            comment << 'Instruction produced on ' + new Date().toGMTString()
            instruction(orAttributes) {
                def folder = new File(orAttributes.fileSet)
                getFolders(folder, "/" + folder.name, out)
            }
        }
        writer.close()

        if (files == 0) file.delete()
    }

    private def getFolders(File folder, def location, def out) {
        if (folder.name[0] != '.') {
            for (File file : folder.listFiles()) {
                if (file.isFile()) {
					out << writeFile(file, location)
                } else {
					if ( recurse ) getFolders(file, location + "/" + file.name, out)
                }
            }
        }
    }

    private def writeFile(File f, def folder) {

        if (f.name.equals("instruction.xml")) return
        if (f.name[0] == '.') return
        if ( f.size() == 0) {
            println("Fatal: file " + f.absolutePath + " has zero bytes.")
            System.exit(1)
        }

        int i = f.name.lastIndexOf('.')
        def extension = (i == -1 || i == f.name.length() - 1) ? null : f.name.substring(i + 1)
        def _contentType = mimeRepository[extension] ?: "application/octet-stream"
        def _md5 = generateMD5(f)

        files++
        String _location = folder + "/" + f.name

        String barcode = f.name.replaceFirst(~/\.[^\.]+$/, '').toUpperCase() // we make the PID the file name
        assert barcode
        String _pid = orAttributes.na + "/" + barcode

        final String _access = getAccessStatus("marc.852\$p=\"${barcode}\"")
        println('\t' + _access)

        return {
            stagingfile {
                pid _pid
                location _location
                contentType _contentType
                md5 _md5
                access _access
            }
        }
    }

    // taken from http://snipplr.com/view/8308/
    private def generateMD5(final file) {
        Date start = new Date()
        digest.reset()
        file.withInputStream() { is ->
            byte[] buffer = new byte[8192]
            int read
            while ((read = is.read(buffer)) > 0) {
                digest.update(buffer, 0, read);
            }
        }
        byte[] md5sum = digest.digest()
        BigInteger bigInt = new BigInteger(1, md5sum)
        def md5 = bigInt.toString(16)
        Date end = new Date()
        long diff = end.getTime() - start.getTime()
        print(file.name + '\t' + md5 + '\t' + file.length() + '\t' + diff / 1000)
        md5
    }

    /**
     * getAccessStatus
     *
     * Retrieves the access from the public SRU service
     */
    private String getAccessStatus(String query) {

        def xml = callSru(orAttributes.sruServer, query)
        String access = xml?.'**'?.find { it.@tag == orAttributes.tag }?.subfield?.find {
            it.'@code' == orAttributes.code
        }?.text() ?: null

        if (!(access in access_stati)) {
            println("Warn: access status unknown or not valid: '${access}'")
            access = ACCESS_DEFAULT
        }

        access
    }

    /**
     * callSru
     *
     * Ask for a record and return the 001 field.
     *
     * @param pid
     * @return
     */
    private static def callSru(String sruServer, String query) {

        def sb = new StringBuilder(sruServer)
                .append('?query=')
                .append(URLEncoder.encode(query, 'UTF-8'))
                .append('&version=1.1')
                .append('&operation=searchRetrieve')
                .append('&recordSchema=info:srw/schema/1/marcxml-v1.1')
                .append('&maximumRecords=1')
                .append('&startRecord=1')
                .append('&resultSetTTL=0')
                .append('&recordPacking=xml')

        try {
            new XmlSlurper().parse(sb.toString())
        } catch (IOException e) {
            println(e.message)
        } catch (SAXException e) {
            println(e.message)
        }
    }
}


def arguments = [xmlns: 'http://objectrepository.org/instruction/1.0/']
for (int i = 0; i < args.length; i++) {
    if (args[i][0] == '-') {
        arguments.put(args[i].substring(1), args[i + 1])
    }
}

["fileSet", "na", "sruServer", "tag", "code"].each {
    assert arguments[it], "Need required argument -$it [value]"
}

def instruction = new SorInstruction(arguments)
println("Start...")
instruction.start()
println("Done. Processed " + instruction.files + " files.")
