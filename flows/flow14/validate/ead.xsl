<xsl:stylesheet
        version="2.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:xlink="http://www.w3.org/1999/xlink"
        xmlns:ext="java:org.Ead"
        xmlns:ead="urn:isbn:1-931666-22-9"
        exclude-result-prefixes="ext xlink ead">

    <xsl:output method="html"/>
    <xsl:param name="archiveIDs" select="'archiveIDs.xml'"/>
    <xsl:variable name="l" select="document($archiveIDs)"/>

    <xsl:template match="/">
        <html>
            <body>
                <table border="1">
                    <caption>Inventarisnummers in de concordantietabel
                        <xsl:value-of select="//ead:eadid[0]/text()"/>
                    </caption>
                    <tr>
                        <th>Inventarisnummer</th>
                        <th>Aanwezig in EAD</th>
                        <th>Afwezig</th>
                    </tr>
                    <xsl:for-each select="$l/list/item">
                        <xsl:variable name="unitid" select="normalize-space(text())"/>
                        <tr>
                            <td>
                                <xsl:value-of select="$unitid"/>
                            </td>
                            <xsl:choose>
                                <xsl:when test="count(//ead:unitid[.=$unitid and not(../../../ead:archdesc)]) = 1">
                                    <td>X</td>
                                    <td><!-- empty --></td>
                                </xsl:when>
                                <xsl:otherwise>
                                    <td><!-- empty --></td>
                                    <td>X</td>
                                </xsl:otherwise>
                            </xsl:choose>
                        </tr>
                    </xsl:for-each>
                </table>
                <table border="1">
                    <caption>Inventarisnummers in de EAD
                        <xsl:value-of select="//ead:eadid[0]/text()"/>
                    </caption>
                    <tr>
                        <th>Inventarisnummer</th>
                        <th>Aanwezig in Concordantietabel</th>
                        <th>Afwezig</th>
                    </tr>
                    <xsl:for-each select="//ead:unitid">

                        <xsl:choose>
                            <xsl:when test="../../../ead:archdesc"/>
                            <xsl:otherwise>
                                <xsl:variable name="unitid" select="normalize-space(text())"/>
                                <tr>
                                    <td>
                                        <xsl:value-of select="text()"/>
                                    </td>
                                    <xsl:choose>
                                        <xsl:when test="count($l/list/item[.=$unitid]) = 1">
                                            <td>X</td>
                                            <td><!-- empty --></td>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <td><!-- empty --></td>
                                            <td>X</td>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </tr>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </table>
            </body>
        </html>
    </xsl:template>

</xsl:stylesheet>
