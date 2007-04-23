set payload(echoString) {<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<SOAP-ENV:Body>
<m:echoString xmlns:m="http://soapinterop.org/">
<inputString>hello world</inputString>
</m:echoString>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>}

set payload(echoInteger) {<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<SOAP-ENV:Body>
<m:echoInteger xmlns:m="http://soapinterop.org/">
<inputInteger>42</inputInteger>
</m:echoInteger>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>}

set payload(echoFloat) {<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<SOAP-ENV:Body>
<m:echoFloat xmlns:m="http://soapinterop.org/">
<inputFloat>0.005</inputFloat>
</m:echoFloat>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>}

set payload(echoVoid) {<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<SOAP-ENV:Body>
<m:echoVoid xmlns:m="http://soapinterop.org/"></m:echoVoid>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>}

set payload(echoBase64) {<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<SOAP-ENV:Body>
<m:echoBase64 xmlns:m="http://soapinterop.org/">
<inputBase64>YUdWc2JHOGdkMjl5YkdRPQ==</inputBase64>
</m:echoBase64>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>}

set payload(echoHexBinary) {<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<SOAP-ENV:Body>
<m:echoHexBinary xmlns:m="http://soapinterop.org/">
<inputHexBinary>68656C6C6F20776F726C6421</inputHexBinary>
</m:echoHexBinary>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>}

set payload(echoDate) {<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<SOAP-ENV:Body>
<m:echoDate xmlns:m="http://soapinterop.org/">
<inputDate>1956-10-18T22:20:00-07:00</inputDate>
</m:echoDate>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>}

set payload(echoDecimal) {<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<SOAP-ENV:Body>
<m:echoDecimal xmlns:m="http://soapinterop.org/">
<inputDecimal>123.45678901234567890</inputDecimal>
</m:echoDecimal>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>}

set payload(echoBoolean) {<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<SOAP-ENV:Body>
<m:echoBoolean xmlns:m="http://soapinterop.org/">
<inputBoolean>1</inputBoolean>
</m:echoBoolean>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>}

ns_write <html><title></title><body>
foreach call [array names payload] {
  set url http://localhost:8000/xosoap/services/SoapInterop2Impl
  set r [::xo::HttpRequest new \
	     -content_type "text/xml" \
	     -url $url \
	     -post_data $payload($call) \
	     -request_header_fields [list SOAPAction $url]]  
  ns_write <p>$call=<pre>[ad_quotehtml [$r set data]]</pre></p>
}
ns_write </body></html>

