<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:mets="http://www.loc.gov/METS/" xmlns:xlink='http://www.w3.org/1999/xlink'>

    <xsl:output method="text"/>
    <xsl:preserve-space elements="*"/>

    <xsl:template match="mets:structMap/mets:div/mets:div[1]/mets:fptr">
        <xsl:variable name="file_id">
            <xsl:value-of select="@FILEID"/>
        </xsl:variable>

        <xsl:apply-templates
                select="//mets:fileGrp[@USE='thumbnail image' or @USE='thumbnail video' or @USE='thumbnail pdf']/mets:file[@ID=$file_id]/mets:FLocat[@LOCTYPE='HANDLE']"
                mode="item_pid"/>
    </xsl:template>

    <xsl:template match="mets:FLocat" mode="item_pid">
        <xsl:value-of select="substring-after(substring-before(@xlink:href, '?'), 'hdl.handle.net/')"/>
    </xsl:template>
</xsl:stylesheet>