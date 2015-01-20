import javax.xml.transform.TransformerFactory
import javax.xml.transform.stream.StreamResult
import javax.xml.transform.stream.StreamSource

String inputFile = args[0]
String params = args[1]
String outputFile = args[2]
String outputTmpFile = outputFile + ".tmp"

def file = new File('ead.xsl')
def stylesheet = new StreamSource(file)
def transformer = TransformerFactory.newInstance().newTransformer(stylesheet)
transformer.setParameter('archiveIDs', params)

final source = new StreamSource(inputFile)
final result = new StreamResult(new File(outputTmpFile))
transformer.transform(source, result)

final tmp = new File(outputTmpFile)
new File(outputFile).withWriter { w ->
    tmp.eachLine { line ->
        w << line.replaceAll(' xmlns=""', '')
    }
}

tmp.deleteOnExit()