import javax.mail.internet.MimeMessage
import javax.mail.Session
import javax.mail.internet.InternetAddress
import javax.mail.Transport


File m = new File(args[0])
def message = m.name + '\n\n'
m.eachLine {
	message+=it
	message+='\n'
}

fromAddress = args[1]
toAddress = args[2]
subject = args[3]
host = args[4]
port = "25"

Properties mprops = new Properties()
mprops.setProperty("mail.transport.protocol", "smtp")
mprops.setProperty("mail.host", host)
mprops.setProperty("mail.smtp.port", port)

Session lSession = Session.getDefaultInstance(mprops, null)
MimeMessage msg = new MimeMessage(lSession)

//tokenize out the recipients in case they came in as a list
StringTokenizer tok = new StringTokenizer(toAddress, ";")
ArrayList emailTos = new ArrayList()
while (tok.hasMoreElements()) {
    emailTos.add(new InternetAddress(tok.nextElement().toString()))
}
InternetAddress[] to = new InternetAddress[emailTos.size()]
to = (InternetAddress[]) emailTos.toArray(to)
msg.setRecipients(MimeMessage.RecipientType.TO, to)
msg.setFrom(new InternetAddress(fromAddress))
msg.setSubject(subject)
msg.setText(message)

Transport transporter = lSession.getTransport("smtp")
transporter.connect()
transporter.send(msg)