<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:or="http://objectrepository.org/instruction/1.0/">

    <xsl:output method="text"/>
    <xsl:preserve-space elements="*"/>

    <xsl:template match="@*|node()">
        <xsl:apply-templates select="@*|node()"/>
    </xsl:template>

    <xsl:template match="or:fileset">
        <xsl:value-of select="concat(or:pid, ',', or:md5)"/>
    </xsl:template>

</xsl:stylesheet>