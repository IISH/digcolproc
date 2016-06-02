import org.xml.sax.SAXException

/**
 * Validate Sru
 *
 * Make sure the identifier exists in our metadata.
 */

/**
 * querySru
 *
 * Fires a query to the sru service and retrieve the desired value.
 */
class QuerySru {

    private def orAttributes

    public QuerySru(def args) {
        orAttributes = args
        println("Loaded class QuerySru with arguments:")
        println(orAttributes)
    }

    void start() {

        def xml = callSru(orAttributes.sruServer, orAttributes.query)
        String value = xml?.'**'?.find { it.@tag == orAttributes.tag }?.subfield?.find {
            it.'@code' == orAttributes.code
        }?.text() ?: orAttributes.access
        println(value)
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


def arguments = [:]
for (int i = 0; i < args.length; i++) {
    if (args[i][0] == '-') {
        arguments.put(args[i].substring(1), args[i + 1])
    }
}

["sruServer", "query", "tag", "code"].each {
    assert arguments[it], "Need required argument -$it [value]"
}

def querySru = new QuerySru(arguments)
querySru.start()