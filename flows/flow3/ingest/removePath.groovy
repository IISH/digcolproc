/**
 * removePath
 *
 * Turn the absolute path into a relative one, by removing the fileSet
 *
 * Usage: [file] [fileSet]
 */

def fileSet = args[1]
String f = new File('/' + fileSet[0]+':' + fileSet[2..-1].replaceAll("\\\\", "/")).toURI().toString()
def replace = [fileSet.replaceAll("\\\\", "\\\\\\\\"), f]

def file = new File(args[0])
def list=[]
file.eachLine ('utf8') {

   replace.each { r ->
       it=it.replaceAll(r, '')
   }
    list << it
}

file.delete()
list.each {
	file.append(it, 'UTF-8')
	file.append("\n")
}

