<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
		xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/">
  <xsl:template match="/">
    <xsl:variable name="endpoint" select="wsdl:definitions/wsdl:service/wsdl:port/soap:address/@location"/>
    <div class="head"><span class="xo">xo</span>soap | <a href="{concat($endpoint,'?s=badge')}"><xsl:value-of select="wsdl:definitions/@name"/></a> | <a href="{concat($endpoint,'?s=wsdl')}">wsdl</a></div>
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:key name='binding' match="wsdl:definitions/wsdl:binding" use='@name'/>
  <xsl:key name='operation' match="wsdl:definitions/wsdl:portType/wsdl:operation" use='@name'/>
  <xsl:key name='message' match="wsdl:definitions/wsdl:message" use='@name'/>
  <xsl:template match="wsdl:service">
	<xsl:for-each select="wsdl:port">
	  <xsl:variable name='binding-local-name'
           select="substring-after(@binding, ':')"/>
	  <!--<p>Binding: 
	  <xsl:value-of select="key('binding',$binding-local-name)"/>
	  </p>-->
	  <ul class="badge">
	  <xsl:for-each select="key('binding',$binding-local-name)/wsdl:operation">
	      <xsl:call-template name="render.operation">
		<xsl:with-param name="operation" select="."/>
	      </xsl:call-template>
	<!--       <xsl:for-each select="wsdl:operation">
	      </xsl:for-each>-->
	  </xsl:for-each>
	  </ul>
	</xsl:for-each>
  </xsl:template>
  <xsl:template name="render.operation">
    <xsl:param name="operation"/>
    <li>

      <h3><xsl:value-of select="$operation/@name"/>(<xsl:value-of select="$operation/preceding-sibling::soap:binding/@style"/>/<xsl:value-of select="$operation/*/*[@use]/@use"/>)</h3>

<!-- | <xsl:value-of select="$operation/*[@style]/@style"/>-->
      <!--SOAP Action: <xsl:value-of select="*[@soapAction]/@soapAction"/>-->
      <xsl:variable name='input-local-name' select="substring-after(key('operation',$operation/@name)/wsdl:input/@message, ':')"/>
      <xsl:variable name='output-local-name' select="substring-after(key('operation',$operation/@name)/wsdl:output/@message, ':')"/>
      <h4>/ input /</h4>
      <xsl:call-template name="render.parts">
	<xsl:with-param name="part" select="key('message',$input-local-name)"/>
      </xsl:call-template>
      
      
      <h4>/ output /</h4>
      <xsl:call-template name="render.parts">
	<xsl:with-param name="part" select="key('message',$output-local-name)"/>
      </xsl:call-template>
    </li>

  </xsl:template>
  <xsl:template name="render.parts">
    <xsl:param name="part"/>
    <xsl:for-each select="$part/wsdl:part">
      <p><xsl:value-of select="@name"/>(<xsl:value-of select="@type"/>)</p>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>