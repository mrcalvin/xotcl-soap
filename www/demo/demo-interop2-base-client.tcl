# / / / / / / / / / / / / / / / / / / /
# Demo
# / / / / / / / / / / / / / / / / / / /
# 	- SOAP Interop2 Base test suite
#	- in simple ProxyObject notation
#	- using gSoap interop2 reference
#	implementation as counterpart
# 
#	see http://www.whitemesa.com/interop.htm
# 	see http://websrv.cs.fsu.edu/~engelen/interop2.cgi
# / / / / / / / / / / / / / / / / / / /
# $Id$

namespace import ::xosoap::client::*
namespace import ::xorb::stub::*
namespace import ::xosoap::xsd::*

set gsoap http://websrv.cs.fsu.edu/~engelen/interop2.cgi
set nusoap http://dietrich.ganx4.com/nusoap/testbed/round2_base_server.php
set soap [SoapGlueObject new \
	     -endpoint $nusoap\
	     -callNamespace http://soapinterop.org/ \
	     -messageStyle ::xosoap::RpcEncoded]

set local [SoapGlueObject new \
	       -endpoint http://localhost:8000/xosoap/services/xosoap/demo/SoapInterop2Impl \
	      -messageStyle ::xosoap::RpcLiteral]
# / / / / / / / / / / / / / 
# see http://www.whitemesa.com/interop/proposal2.html
# for interface description

ProxyObject SoapInterop2Base -glueobject $local


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
  ::xorb::datatypes::AnyAttribute varString -anyType ::xosoap::xsd::XsString
  ::xorb::datatypes::AnyAttribute varInt -anyType ::xosoap::xsd::XsInteger
  ::xorb::datatypes::AnyAttribute varFloat -anyType ::xosoap::xsd::XsFloat
}

set struct [exampleStruct new]
$struct varString "hello world"
$struct varInt "42"
$struct varFloat 0.005

SoapInterop2Base ad_proc -returns soapStruct(::template::exampleStruct) \
    echoStruct {-inputStruct:soapStruct(::template::exampleStruct)}\
    {see http://www.whitemesa.com/interop/proposal2.html#echoStruct} \
    {}
set r [SoapInterop2Base echoStruct -inputStruct $struct]
ns_write "<p>echoStruct(varFloat)=[$r varFloat]<br/>echoStruct(varInt)=[$r varInt]<br/>echoStruct(varString)=[$r varString]</p>"

# / / / / / / / / / / / / / 
# echoStringArray
# http://www.whitemesa.com/interop/proposal2.html#echoStringArray

set stringArray [ArrayBuilder new -type ::xosoap::xsd::XsString -size 2]
set i [$stringArray new]
$i 0 hello
$i 1 world

SoapInterop2Base ad_proc -returns soapArray(xsString)<2> \
    echoStringArray {-inputStringArray:soapArray(xsString)<2>}\
    {see http://www.whitemesa.com/interop/proposal2.html#echoStringArray} \
    {}

set r [SoapInterop2Base echoStringArray -inputStringArray $i]
ns_write "<p>echoStringArray(0)=[$r 0]<br/>echoStringArray(1)=[$r 1]</p>"

# / / / / / / / / / / / / / 
# echoIntegerArray
# http://www.whitemesa.com/interop/proposal2.html#echoIntegerArray

set integerArray [ArrayBuilder new -type ::xosoap::xsd::XsInteger -size 2]
set i [$integerArray new]
$i 0 100
$i 1 200

SoapInterop2Base ad_proc -returns soapArray(xsInteger)<2> \
    echoIntegerArray {-inputIntegerArray:soapArray(xsInteger)<2>}\
    {see http://www.whitemesa.com/interop/proposal2.html#echoIntegerArray} \
    {}

set r [SoapInterop2Base echoIntegerArray -inputIntegerArray $i]
ns_write "<p>echoIntegerArray(0)=[$r 0]<br/>echoIntegerArray(1)=[$r 1]</p>"

# / / / / / / / / / / / / / 
# echoFloatArray
# http://www.whitemesa.com/interop/proposal2.html#echoFloatArray

set floatArray [ArrayBuilder new -type ::xosoap::xsd::XsFloat -size 2]
set i [$floatArray new]
$i 0 0.00000555
$i 1 12999.9

SoapInterop2Base ad_proc -returns soapArray(xsFloat)<2> \
    echoFloatArray {-inputFloatArray:soapArray(xsFloat)<2>}\
    {see http://www.whitemesa.com/interop/proposal2.html#echoFloatArray} \
    {}

set r [SoapInterop2Base echoFloatArray -inputFloatArray $i]
ns_write "<p>echoFloatArray(0)=[$r 0]<br/>echoFloatArray(1)=[$r 1]</p>"

# / / / / / / / / / / / / / 
# echoStructArray
# http://www.whitemesa.com/interop/proposal2.html#echoStructArray

set structArray [ArrayBuilder new \
		     -type ::template::exampleStruct \
		     -size 2]
ns_log notice structArray=[$structArray serialize]
set i [$structArray new]
$i 0 [exampleStruct new \
	  -varInt 42 \
	  -varString "hello world" \
	  -varFloat 0.005]
$i 1 [exampleStruct new \
	  -varInt 42 \
	  -varString "hello world" \
	  -varFloat 0.005]

#ns_log notice i=[$i serialize]

SoapInterop2Base ad_proc -returns soapArray(soapStruct(::template::exampleStruct))<2> \
    echoStructArray {-inputStructArray:soapArray(soapStruct(::template::exampleStruct))<2>}\
    {see http://www.whitemesa.com/interop/proposal2.html#echoStructArray} \
    {}

set r [SoapInterop2Base echoStructArray -inputStructArray $i]
ns_write "<p>echoStructArray(0,varString)=[[$r 0] varString]<br/>echoStructArray(1,varFloat)=[[$r 1] varFloat]</p>"