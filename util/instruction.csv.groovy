import groovy.xml.StreamingMarkupBuilder
import java.security.MessageDigest

/**
 * SorInstruction
 *
 * Creates a OR instruction for the submission package.
 *
 * The procedure iterates line by line through a csv to get the desired md5 and content type values.
 *
 */

class SorInstruction {

    private def orAttributes
    def files = 0
    private MessageDigest digest = MessageDigest.getInstance("MD5")

    public SorInstruction(def args) {
        orAttributes = args
        println("Loaded instruction class with arguments:")
        println(orAttributes)

        final file = new File(orAttributes.fileSet)
        orAttributes.access = orAttributes.access ?: 'open'
        orAttributes.archivalID = file.name
        orAttributes.na = file.parentFile.name
    }

    void start() {
        def defaultAccess = getCustom(new File(orAttributes.fileSet, '.access.txt'))

        final fileSetFolder = new File(orAttributes.fileSet)
        def file = new File(fileSetFolder, "instruction.xml")
        def writer = file.newWriter('UTF-8')
        def builder = new StreamingMarkupBuilder()
        builder.setEncoding("utf-8")
        builder.setUseDoubleQuotes(true)

        final csv = new File(orAttributes.csv)
        assert csv.exists()

        writer << builder.bind {
            mkp.xmlDeclaration()
            comment << 'Instruction produced on ' + new Date().toGMTString()
            instruction(orAttributes) {
                csv.eachLine {
                    def split = it.split(",")
                    assert split.length == 6
                    if (split[0] != "objnr") {
                        files++
                        final file_master = new File(fileSetFolder.parentFile, split[2])
                        if ( file_master.size() == 0) {
                            println("Fatal: file " + file_master.absolutePath + " has zero bytes.")
                            System.exit(1)
                        }
                        String _md5 = generateMD5(file_master)
                        String _objid = orAttributes.na + '/' + orAttributes.archivalID + "." + split[1]
                        def _access = getCustom(new File(file_master.parentFile, '.access.txt'))
                        stagingfile
                                {
                                    pid(split[5])
                                    location(split[2])
                                    md5(_md5)
                                    (_access) ? access(_access) : access(defaultAccess)
                                    objid(_objid)
                                    seq(split[4])
                                }
                    }
                }
            }
        }
        writer.close()
        if (files == 0) file.delete()
    }

    private String getCustom(File file) {
        if (file.exists()) {
            file.eachLine {
                return it.trim()
            }
        }
        orAttributes.access
    }

    // taken from http://snipplr.com/view/8308/
    private def generateMD5(File file) {

        assert file.exists()
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
        println(file.name + "\t" + md5 + "\t" + file.length() + "\t" + diff / 1000)
        md5
    }
}


def arguments = [xmlns: 'http://objectrepository.org/instruction/1.0/']
for (int i = 0; i < args.length; i++) {
    if (args[i][0] == '-') {
        arguments.put(args[i].substring(1), args[i + 1])
    }
}

["csv", "fileSet"].each {
    assert arguments[it], "Need required argument -$it [value]"
}

def instruction = new SorInstruction(arguments)
println("Start...")
instruction.start()
println("Done. Processed " + instruction.files + " files.")