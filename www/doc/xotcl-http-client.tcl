ad_page_contract {

      @author Stefan Sobernig
} {
    
}

package require xotcl::comm::httpAccess

# aligning to AOLServer environment

xotcl::comm::httpAccess::Http set useragent "xoSoap"
proc ::printError {msg} { ns_log notice $msg}
proc ::showMsg {msg} { ns_log notice $msg }


::xotcl::Class SoapRequest -superclass SimpleRequest -parameter {endpoint payload}
	
	SoapRequest ad_instproc init {} {} {
	
		my instvar endpoint payload
		
		my url $endpoint
		my method "POST"
		my headers [list SOAPAction $endpoint]
		my data $payload
		my contentType "text/xml"
		
		next
		
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

# simple test call

SoapRequest s0 -endpoint http://localhost:8000/xosoap/services/SqiService1 -payload $payload

ns_return 200 text/xml [s0 getContent]
s0 destroy
#set hostport media.wu-wien.ac.at/download/README-xotcl-core
#SimpleRequest r0 -url http://$hostport
#ns_return 200 text/plain [r0 getContent]
#r0 destroy