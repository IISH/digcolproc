<xsl:stylesheet
        version="2.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:xlink="http://www.w3.org/1999/xlink"
        xmlns:ext="java:org.Ead"
        xmlns:ead="urn:isbn:1-931666-22-9"
        exclude-result-prefixes="ext xlink ead"
        >

    <xsl:param name="archiveIDs" select="'archiveIDs.xml'"/>
    <xsl:variable name="l" select="document($archiveIDs)"/>
    <xsl:variable name="archivalID" select="substring(ead:ead/ead:eadheader/ead:eadid/@identifier, 5)"/>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:did/ead:unitid">

        <xsl:variable name="unitid" select="normalize-space(text())"/>
        <unitid>
            <xsl:value-of select="$unitid"/>
        </unitid>

        <xsl:variable name="encoded">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$unitid"/>
                <xsl:with-param name="replace">
                    <xsl:text> </xsl:text>
                </xsl:with-param>
                <xsl:with-param name="by" select="'%20'"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="pid"
                      select="concat($archivalID, '%2E', $encoded)"/>

        <xsl:if test="$l/list/item[.=$unitid]">
            <daogrp xlink:type="extended">
                <xsl:element name="daoloc">
                    <xsl:attribute name="xlink:href">
                        <xsl:value-of select="concat('http://hdl.handle.net/', $pid,  '?locatt=view:level3')"/>
                    </xsl:attribute>
                    <xsl:attribute name="xlink:type">locator</xsl:attribute>
                    <xsl:attribute name="xlink:label">thumbnail</xsl:attribute>
                </xsl:element>
                <xsl:element name="daoloc">
                    <xsl:attribute name="xlink:href">
                        <xsl:value-of select="concat('http://hdl.handle.net/', $pid,  '?locatt=view:pdf')"/>
                    </xsl:attribute>
                    <xsl:attribute name="xlink:type">locator</xsl:attribute>
                    <xsl:attribute name="xlink:label">pdf</xsl:attribute>
                </xsl:element>
                <xsl:element name="daoloc">
                    <xsl:attribute name="xlink:href">
                        <xsl:value-of select="concat('http://hdl.handle.net/', $pid,  '?locatt=view:mets')"/>
                    </xsl:attribute>
                    <xsl:attribute name="xlink:type">locator</xsl:attribute>
                    <xsl:attribute name="xlink:label">mets</xsl:attribute>
                </xsl:element>
                <xsl:element name="daoloc">
                    <xsl:attribute name="xlink:href">
                        <xsl:value-of select="concat('http://hdl.handle.net/', $pid,  '?locatt=view:catalog')"/>
                    </xsl:attribute>
                    <xsl:attribute name="xlink:type">locator</xsl:attribute>
                    <xsl:attribute name="xlink:label">catalog</xsl:attribute>
                </xsl:element>
            </daogrp>
        </xsl:if>

    </xsl:template>

    <xsl:template name="string-replace-all">
        <xsl:param name="text"/>
        <xsl:param name="replace"/>
        <xsl:param name="by"/>
        <xsl:choose>
            <xsl:when test="contains($text,$replace)">
                <xsl:value-of select="substring-before($text,$replace)"/>
                <xsl:value-of select="$by"/>
                <xsl:call-template name="string-replace-all">
                    <xsl:with-param name="text" select="substring-after($text,$replace)"/>
                    <xsl:with-param name="replace" select="$replace"/>
                    <xsl:with-param name="by" select="$by"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
