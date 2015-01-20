/**
 * Validate Sru
 *
 * Make sure the identifier exists in our metadata.
 */

class validateSru {

    private def orAttributes
    private final def files = 0
    private final boolean recurse = false
    private final def good = []
    private final def bad = []
    private final String pattern = ~/^[\sa-zA-Z0-9-:\._()\[\]\{@\$\}=\\]{1,240}$/

    public validateSru(def args) {
        orAttributes = args
        println("Loaded class validateSru { class with arguments:")
        println(orAttributes)
        recurse = (Boolean.parseBoolean(orAttributes.recurse))
    }

    void start() {
        def file = new File(orAttributes.work, "validation.txt")
        def folder = new File(orAttributes.fileSet)
        getFolders(folder, "/" + folder.name)

        def writer = file.newWriter('UTF-8')
        writer.writeLine("Started validation on " + new Date().toGMTString())

        if ( !bad && !good )
            writer.writeLine('No files.')

        if (bad) {
            writer.writeLine(bad.size + ' mislukt:')
            bad.each {
                writer.writeLine(it)
            }
        }

        writer.newLine()

        if (good) {
            writer.writeLine(good.size + ' gelukt:')
            good.each {
                writer.writeLine(it)
            }
        }
        writer.close()
    }

    private def getFolders(File folder, def location) {
        if (folder.name[0] != '.') {
            for (File file : folder.listFiles()) {
                if (file.isFile()) {
                    writeFile(file, location)
                } else {
                    if (recurse) getFolders(file, location + "/" + file.name)
                }
            }
        }
    }

    private void writeFile(File f, def folder) {

        if (f.name.equals("instruction.xml")) return
        if (f.name.equals("validation.txt")) return
        if (f.name[0] == '.') return
        files++
        String _location = folder + "/" + f.name
        String _pid = f.name.replaceFirst(~/\.[^\.]+$/, '').trim() // we make the PID the file name

        if ( f.size() == 0 ) {
            bad << _location + "\t" + _pid + "\tDe lengte van de file is leeg."
            return
        }

        if (_pid) {
            if (_pid.matches(pattern)) {
                def marc001 = callSru(_pid)
                if (marc001)
                    good << _location + "\t" + _pid + "\t" + marc001
                else
                    bad << _location + "\t" + _pid + "\tgeen metadata gevonden"
            } else
                bad << _location + "\t" + _pid + "\tfilenaam is ongeldig"
        } else
            bad << _location + "\t" + _pid + "\tfilenaam is ongeldig"
    }

    /**
     * callSru
     *
     * Ask for a record and return the 001 field.
     *
     * @param pid
     * @return
     */
    private def callSru(String _marc852p) {

        def sb = new StringBuilder(orAttributes.sruServer)
                .append('?query=')
                .append(URLEncoder.encode('marc.852$p=\"' + _marc852p + '\"', "UTF-8"))
                .append('&version=1.1')
                .append('&operation=searchRetrieve')
                .append('&recordSchema=info:srw/schema/1/marcxml-v1.1')
                .append('&maximumRecords=1')
                .append('&startRecord=1')
                .append('&resultSetTTL=0')
                .append('&recordPacking=xml')

        println("request=${sb}")

        def xml = null
        try {
            xml = new XmlSlurper().parse(sb.toString())
        } catch (Exception e) {
            println(e)
        }
        xml?.'**'?.find { it.@tag == '001' }?.text()
    }

}




def arguments = [xmlns: 'http://objectrepository.org/instruction/1.0/']
for (int i = 0; i < args.length; i++) {
    if (args[i][0] == '-') {
        arguments.put(args[i].substring(1), args[i + 1])
    }
}

["fileSet", "na", "sruServer", "work"].each {
    assert arguments[it], "Need required argument -$it [value]"
}

def instruction = new validateSru(arguments)
println("Start...")
instruction.start()
println("Done. Processed " + instruction.files + " files.")
