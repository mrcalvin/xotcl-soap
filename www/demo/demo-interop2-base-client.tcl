# / / / / / / / / / / / / / / / / / / /
# Demo
# / / / / / / / / / / / / / / / / / / /
# 	- SOAP Interop2 Base test suite
#	- in simple GObject notation
#	- using gSoap interop2 reference
#	implementation as counterpart
# 
#	see http://www.whitemesa.com/interop.htm
# 	see http://websrv.cs.fsu.edu/~engelen/interop2.cgi
# / / / / / / / / / / / / / / / / / / /
# $Id$

namespace import ::xosoap::client::*
namespace import ::xorb::stub::*

set soap [SoapGlueObject new \
	     -endpoint http://websrv.cs.fsu.edu/~engelen/interop2.cgi \
	     -callNamespace http://soapinterop.org/]

set local [SoapGlueObject new \
	       -endpoint http://localhost:8000/xosoap/services/SoapInterop2Impl]
# / / / / / / / / / / / / / 
# see http://www.whitemesa.com/interop/proposal2.html
# for interface description

GObject SoapInterop2Base -glueobject $soap


# / / / / / / / / / / / / /
# Section 1
# Primitive data types

# / / / / / / / / / / / / / 
# echoString
#  http://www.whitemesa.com/interop/proposal2.html#echoString

SoapInterop2Base ad_proc -returns xsString \
    echoString {-inputString:xsString} \
    {see http://www.whitemesa.com/interop/proposal2.html#echoString} \
    {}

ns_write "<p>echoString=[SoapInterop2Base echoString -inputString echoMe]</p>"

# / / / / / / / / / / / / / 
# echoInteger
# http://www.whitemesa.com/interop/proposal2.html#echoInteger

SoapInterop2Base ad_proc -returns xsInteger \
    echoInteger {-inputInteger:xsInteger} \
    {see http://www.whitemesa.com/interop/proposal2.html#echoInteger} \
    {}

ns_write "<p>echoInteger=[SoapInterop2Base echoInteger -inputInteger 42]</p>"

# / / / / / / / / / / / / / 
# echoFloat
# http://www.whitemesa.com/interop/proposal2.html#echoFloat

SoapInterop2Base ad_proc -returns xsFloat \
    echoFloat {-inputFloat:xsFloat} \
    {see http://www.whitemesa.com/interop/proposal2.html#echoFloat} \
    {}
ns_write "<p>echoFloat=[SoapInterop2Base echoFloat -inputFloat 0.005]</p>"

# / / / / / / / / / / / / / 
# echoVoid
# http://www.whitemesa.com/interop/proposal2.html#echoVoid

SoapInterop2Base ad_proc -returns xsVoid \
    echoVoid {}\
    {see http://www.whitemesa.com/interop/proposal2.html#echoVoid} \
    {}
ns_write "<p>echoVoid=[SoapInterop2Base echoVoid]</p>"

# / / / / / / / / / / / / / 
# echoBase64
# http://www.whitemesa.com/interop/proposal2.html#echoBase64

SoapInterop2Base ad_proc -returns xsBase64Binary \
    echoBase64 {-inputBase64:xsBase64Binary}\
    {see http://www.whitemesa.com/interop/proposal2.html#echoBase64} \
    {}
ns_write "<p>echoBase64=[SoapInterop2Base echoBase64 -inputBase64 YUdWc2JHOGdkMjl5YkdRPQ==]</p>"

# / / / / / / / / / / / / / 
# echoHexBinary
# http://www.whitemesa.com/interop/proposal2.html#echoHexBinary

SoapInterop2Base ad_proc -returns xsHexBinary \
    echoHexBinary {-inputHexBinary:xsHexBinary}\
    {see http://www.whitemesa.com/interop/proposal2.html#echoHexBinary} \
    {}
ns_write "<p>echoHexBinary=[SoapInterop2Base echoHexBinary -inputHexBinary 68656C6C6F20776F726C6421]</p>"

# / / / / / / / / / / / / / 
# echoDate
# http://www.whitemesa.com/interop/proposal2.html#echoDate

SoapInterop2Base ad_proc -returns xsDateTime \
    echoDate {-inputDate:xsDateTime}\
    {see http://www.whitemesa.com/interop/proposal2.html#echoDate} \
    {}
ns_write "<p>echoDate=[SoapInterop2Base echoDate -inputDate 1956-10-18T22:20:00-07:00]</p>"

# / / / / / / / / / / / / / 
# echoDecimal
# http://www.whitemesa.com/interop/proposal2.html#echoDecimal

SoapInterop2Base ad_proc -returns xsDecimal \
    echoDecimal {-inputDecimal:xsDecimal}\
    {see http://www.whitemesa.com/interop/proposal2.html#echoDecimal} \
    {}
ns_write "<p>echoDecimal=[SoapInterop2Base echoDecimal -inputDecimal 123.45678901234567890]</p>"

# / / / / / / / / / / / / / 
# echoBoolean
# http://www.whitemesa.com/interop/proposal2.html#echoBoolean

SoapInterop2Base ad_proc -returns xsBoolean \
    echoBoolean {-inputBoolean:xsBoolean}\
    {see http://www.whitemesa.com/interop/proposal2.html#echoBoolean} \
    {}
ns_write "<p>echoBoolean=[SoapInterop2Base echoBoolean -inputBoolean 1]</p>"


# / / / / / / / / / / / / /
# Section 2
# Complex data types

# / / / / / / / / / / / / / 
# echoStruct
# http://www.whitemesa.com/interop/proposal2.html#echoStruct


Class exampleStruct -slots {
  ::xorb::datatypes::AnyAttribute varString -type ::xosoap::xsd::XsString
  ::xorb::datatypes::AnyAttribute varInt -type ::xosoap::xsd::XsInteger
  ::xorb::datatypes::AnyAttribute varFloat -type ::xosoap::xsd::XsFloat
}

set struct [exampleStruct new]
$struct varString "hello world"
$struct varInt "42"
$struct varFloat 0.005

SoapInterop2Base ad_proc -returns object=::template::exampleStruct \
    echoStruct {-inputStruct:object=::template::exampleStruct}\
    {see http://www.whitemesa.com/interop/proposal2.html#echoStruct} \
    {}
ns_write "<p>echoStruct=[SoapInterop2Base echoStruct -inputStruct $struct]</p>"