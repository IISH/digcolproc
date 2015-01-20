import org.xml.sax.SAXException

/**
 * harvest.groovy
 *
 * harvest a repository.
 * extract from the records the barcodes and associated 542$m values.
 * create an instruction from it.
 *
 * Resume on error, unless we have more than 100 such events.
 */

class Oai2Harvester {

    private def orAttributes
    def records = 0
    private def required = ['na', 'baseURL', 'verb']
    private static String ACCESS_DEFAULT = 'closed'
    private static int PAUSE_SECONDS = 10
    private static access_stati = ['open', 'restricted', 'closed', 'irsh']

    public Oai2Harvester(def args) {
        orAttributes = args
        message("Loaded harvester class with arguments:")
        orAttributes.each {
            message(it.toString())
        }

        required.each {
            assert orAttributes[it]
        }
    }

    void start() {

        harvest()
    }

    void harvest() {

        String resumptionToken = " "
        while (resumptionToken) {

            def request = new StringBuilder((String) orAttributes.baseURL + '?verb=' + orAttributes.verb)
            if (resumptionToken.trim())
                request.append('&resumptionToken=' + resumptionToken)
            else
                ['identify', 'from', 'until', 'set', 'metadataPrefix'].each {
                    if (orAttributes[it])
                        request.append('&' + it + '=' + orAttributes[it])
                }

            def response = null
            while (!response) {
                response = getResponse(request.toString())
            }

            response.'ListRecords'?.'record'?.'metadata'?.record?.each {
                record(it)
            }

            resumptionToken = response.'ListRecords'?.resumptionToken
        }
    }

    static def getResponse(String url) {

        def response = null
        try {
            message('Request: ' + url)
            response = new XmlSlurper().parse(url)
        } catch (Exception exception) {
            message('Error: ' + exception.message)
            pause()
        }

        response
    }

    static synchronized void pause() {
        //wait 5 seconds before resuming.
        message("Wait ${PAUSE_SECONDS} seconds before resuming due to the last exception.")
        wait(PAUSE_SECONDS * 1000)
    }

    static void message(String text) {

        def d = new Date().format("yyyy-MM-dd'T'hh:mm:ss")
        println('# ' + d + ' ' + text)
    }

    /**
     * record
     *
     * Retrieve the identifier 001, 542$m and 852$p (R)
     *
     * @param record
     */
    void record(def record) {

        // Get the identifier
        String cf_001 = record.controlfield?.find {
            it.'@tag' == '001'
        }?.text()

        // Get the access code.
        String df_542m = normalize(record.datafield?.find {
            it.'@tag' == '542'
        }?.subfield?.find {
            it.'@code' == 'm'
        }?.text()) ?: ACCESS_DEFAULT

        if (!(df_542m in access_stati)) {
            message(df_542m + ' is not a known access status value. Applying default: ' + ACCESS_DEFAULT)
            df_542m = ACCESS_DEFAULT
        }

        // Get the barcodes ( they start with 30051 and have 14 digits ).
        def barcodes = record.datafield?.inject([]) { visitor, it ->
            def subfield = it.subfield?.find { it.'@code' == 'p' && it.text() =~ /^30051\d{9}/ }
            if (subfield)
                visitor << orAttributes.na + '/' + subfield.text()
            visitor
        }

        // 001 542$m barcode
        records++
        barcodes?.each {
            println(cf_001 + ',' + df_542m + ',' + it)
        }
    }

    /**
     * Normalize the access status value
     *  - lowercase
     *  - only alphanumeric
     * @param p
     * @return
     */
    static String normalize(String s) {

        s?.findAll {
            it =~ '[a-zA-Z0-9]'
        }?.join('')?.toLowerCase()
    }
}

def arguments = [:]
for (
        int i = 0;
        i < args.length; i++) {
    if (args[i][0] == '-') {
        arguments.put(args[i].substring(1), args[i + 1])
    }
}

def harvester = new Oai2Harvester(arguments)
Oai2Harvester.message("Start...")
harvester.start()
Oai2Harvester.message("Done. Processed " + harvester.records + " files.")