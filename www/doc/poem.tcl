package req SOAP

SOAP::create getPoem \
	-uri "urn:xmethods-getPoem" \
	-proxy "http://localhost/xosoap/services/Poem" \
	-params { "statement" "string" }	

puts [getPoem "is a rose"]
