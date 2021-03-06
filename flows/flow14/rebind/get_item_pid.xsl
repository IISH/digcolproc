<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:mets="http://www.loc.gov/METS/" xmlns:xlink='http://www.w3.org/1999/xlink'>

    <xsl:output method="text"/>
    <xsl:preserve-space elements="*"/>

    <xsl:template match="@*|node()">
        <xsl:apply-templates select="@*|node()"/>
    </xsl:template>

    <xsl:template match="mets:fileGrp[@USE='thumbnail image']/mets:file[1]/mets:FLocat[@LOCTYPE='HANDLE']">
    <xsl:value-of select="substring-after(substring-before(@xlink:href, '?'), 'hdl.handle.net/')"/>
    </xsl:template>


</xsl:stylesheet>