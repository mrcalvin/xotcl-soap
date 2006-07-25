ad_page_contract {

      @author Stefan Sobernig
} {
    
}

set payload {

	<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" 
xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsd="http://www.w3.org/1999/
XMLSchema" xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance">
    <SOAP-ENV:Body>
        <ns:synchronousQuery xmlns:ns="urn:xmethods-getPoem">
            <statement xsi:type="xsd:string">beneath the wheel</statement>
        </ns:synchronousQuery>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
}

::xosoap::client::SoapRequest s0 -volatile  -endpoint http://localhost:8000/xosoap/services/SqiService1 -payload $payload

ns_return 200 text/xml [s0 getContent]