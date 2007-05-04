# / / / / / / / / / / / / / / / / / / /
# Demo
# / / / / / / / / / / / / / / / / / / /
# Romulan<>Digital Conversion
# - example in simple GObject notation 
# - per-method glue object 
# - see http://www.ebob42.com/cgi-bin/Romulan.exe/wsdl/IRoman
# / / / / / / / / / / / / / / / / / / /
# $Id$


namespace import -force ::xosoap::client::*
namespace import -force ::xorb::stub::*


# / / / / / / / / / / / / / / / / / / /
# 1) create a 'glue' object
set s1 [SoapGlueObject new \
	    -endpoint http://www.ebob42.com/cgi-bin/Romulan.exe/soap/IRoman \
	    -callNamespace "urn:Roman-IRoman" \
	    -action "urn:Roman-IRoman#RomanToInt"]

# / / / / / / / / / / / / / / / / / / /
# 2) provide the 'object' to a proxy client /
# stub object and declare the remote object
# interface

GObject RomulanConverter
RomulanConverter ad_proc \
    -glueobject $s1 \
    -returns xsInteger RomanToInt {
      -Rom:xsString
} {Converts romulan value in decimal equivalent} {}

$s1 action urn:Roman-IRoman#IntToRoman
RomulanConverter ad_proc \
    -glueobject $s1 \
    -returns xsString IntToRoman {
      -Int:xsInteger
} {Converts decimal value in roman equivalent} {}


ns_write "OpenACS and dotLRN Spring Conference [RomulanConverter RomanToInt -Rom MMVII]"
ns_write "OpenACS and dotLRN Spring Conference [RomulanConverter IntToRoman -Int 2007]"
