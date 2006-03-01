package req SOAP

SOAP::create getPoem \
	-uri "urn:xmethods-getPoem" \
	-proxy "http://192.168.1.128/xosoap/services/Poem" \
	-params { "statement" "string" }	

puts "===================="
puts [getPoem "is a rose"]
puts "===================="