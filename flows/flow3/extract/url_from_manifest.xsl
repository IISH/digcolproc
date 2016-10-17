<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:mets="http://www.loc.gov/METS/" xmlns:xlink='http://www.w3.org/1999/xlink'>

    <xsl:output method="text"/>
    <xsl:preserve-space elements="*"/>

    <xsl:template match="@*|node()">
        <xsl:apply-templates select="@*|node()"/>
    </xsl:template>

    <xsl:template match="mets:fileGrp[@ID='master']/mets:file/mets:FLocat">
<xsl:value-of select="concat(substring-after(@xlink:href, 'http://hdl.handle.net/'), ' ', @xlink:title)" />
<xsl:text>
</xsl:text>
    </xsl:template>


</xsl:stylesheet>