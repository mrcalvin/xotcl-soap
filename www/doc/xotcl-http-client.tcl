ad_page_contract {

      @author Stefan Sobernig
} {
    
}


set payload {<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance">
    <SOAP-ENV:Body>
        <ns:synchronousQuery xmlns:ns="urn:xmethods-synchronousQuery">
            <queryStatement soap-enc:arrayType="xsd:int[2]">
   				<number>3</number>
   				<number>4</number>
		</queryStatement>
        </ns:synchronousQuery>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>}

# simple test call

::xosoap::client::SoapRequest s0 -endpoint http://localhost:8000/xosoap/services/ComplexSqiService -payload $payload

ns_return 200 text/xml [s0 getContent]
s0 destroy
#set hostport media.wu-wien.ac.at/download/README-xotcl-core
#SimpleRequest r0 -url http://$hostport
#ns_return 200 text/plain [r0 getContent]
#r0 destroy