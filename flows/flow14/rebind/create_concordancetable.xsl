<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ead="urn:isbn:1-931666-22-9">

    <xsl:output method="text"/>
    <xsl:preserve-space elements="*"/>

    <xsl:template match="@*|node()">
        <xsl:apply-templates select="@*|node()"/>
    </xsl:template>

    <xsl:template match="ead:dsc">
        <xsl:text>"Objectnummer","Inventarisnummer"</xsl:text>
        <xsl:for-each select="node()//ead:unitid[not(../../*/ead:did/ead:unitid)]">

            <xsl:variable name="file_title">
                <xsl:apply-templates select="../../../../../../../../../../../../../../ead:did"/>
                <xsl:apply-templates select="../../../../../../../../../../../../../ead:did"/>
                <xsl:apply-templates select="../../../../../../../../../../../../ead:did"/>
                <xsl:apply-templates select="../../../../../../../../../../../ead:did"/>
                <xsl:apply-templates select="../../../../../../../../../../ead:did"/>
                <xsl:apply-templates select="../../../../../../../../../ead:did"/>
                <xsl:apply-templates select="../../../../../../../../ead:did"/>
                <xsl:apply-templates select="../../../../../../../ead:did"/>
                <xsl:apply-templates select="../../../../../../ead:did"/>
                <xsl:apply-templates select="../../../../../ead:did"/>
                <xsl:apply-templates select="../../../../ead:did"/>
                <xsl:apply-templates select="../../../ead:did"/>
            </xsl:variable>
            <xsl:text>
</xsl:text>
            <xsl:value-of
                    select="concat('&quot;', position(), '&quot;,&quot;', text(), '&quot;')"/>
        </xsl:for-each>
    </xsl:template>


</xsl:stylesheet>