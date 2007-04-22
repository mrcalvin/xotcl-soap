# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# +-+-+-+-+-+-+ +-+-+-+-+ +-+-+-+-+-+
# |x|o|s|o|a|p| |t|e|s|t| |s|u|i|t|e|
# +-+-+-+-+-+-+ +-+-+-+-+ +-+-+-+-+-+
# author: stefan.sobernig@wu-wien.a.at
# cvs-id: $Id$
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

namespace import -force ::xoexception::try

Object test
test set passed 0
test set failed 0
test proc case msg {ad_return_top_of_page "<title>$msg</title><h2>$msg</h2>"} 
test proc section msg    {my reset; ns_write "<hr><h3>$msg</h3>"} 
test proc subsection msg {ns_write "<h4>$msg</h4>"} 
test proc errmsg msg     {ns_write "ERROR: $msg<BR/>"; test incr failed}
test proc okmsg msg      {ns_write "OK: $msg<BR/>"; test incr passed}
test proc code msg       {ns_write "<pre>$msg</pre>"}
test proc reset {} {
  array unset ::xotcl_cleanup
  global af_parts  af_key_name
  array unset af_parts
  array unset af_key_name
}

proc ? {cmd expected {msg ""}} {
   set r [uplevel $cmd]
   if {$msg eq ""} {set msg $cmd}
   if {$r ne $expected} {
     test errmsg "$msg returned '$r' ne '$expected'"
   } else {
     test okmsg "$msg - passed ([t1 diff] ms)"
   }
}

proc ?+ {cmd {msg ""}} {
  if {$msg eq ""} {set msg $cmd}
  try {
    set r [uplevel $cmd]
    test okmsg "$msg passed ([t1 diff] ms)"
  } catch {Exception e} {
    test errmsg "$msg failed: <pre>[ad_quotehtml [$e set __message__([[$e info class] contentType])]]</pre>"
  } catch {error e} {
    test errmsg "$msg failed: $e"
  }
  
}

proc ?++ {cmd expected {msg ""}} {
  if {$msg eq ""} {set msg $cmd}
  try {
    set r [uplevel $cmd]
    if {$r ne $expected} {
      test errmsg "$msg returned '$r' ne '$expected'"
    } else { 
      test okmsg "$msg passed ([t1 diff] ms)"
    }
  } catch {Exception e} {
    test errmsg "$msg failed: <pre>[ad_quotehtml [$e set __message__([[$e info class] contentType])]]</pre>"
  } catch {error e} {
    test errmsg "$msg failed: $e"
  }
}

# / / / / / / / / / / / / / / /
# Negative-expected test 
# Suceeds if certain expected
# exception is caught!
# knows four states.

proc ?-- {cmd expected {msg ""}} {
  if {$msg eq ""} {set msg $cmd}
  try {
    set r [uplevel $cmd]
    test errmsg "$msg failed due to NO error"
  } catch {Exception e} {
    if {[$e istype $expected]} {
      test okmsg "$msg passed ([t1 diff] ms):<pre>[ad_quotehtml [$e set __message__([[$e info class] contentType])]]</pre>"
    } else {
      test errmsg "$msg failed due to UNEXPECTED exception:<pre>[ad_quotehtml [$e set __message__([[$e info class] contentType])]]</pre>"
    }
  } catch {error e} {
    test errmsg "$msg failed due to UNEXPECTED error: $e"
  }
  
}

proc ?- {cmd expected {msg ""}} {
  if {$msg eq ""} {set msg $cmd}
  set status [catch {set r [uplevel $cmd]} catchMsg]
  if {$status eq $expected} {
    test okmsg "$msg passed: $status eq $expected"
  } else {
    test errmsg "$msg failed: $status ne $expected"
  }
}

 Class Timestamp
  Timestamp instproc init {} {my set time [clock clicks -milliseconds]}
  Timestamp instproc diffs {} {
    set now [clock clicks -milliseconds]
    set ldiff [expr {[my exists ltime] ? [expr {$now-[my set ltime]}] : 0}]
    my set ltime $now
    return [list [expr {$now-[my set time]}] $ldiff]
  }
  Timestamp instproc diff {{-start:switch}} {
    lindex [my diffs] [expr {$start ? 0 : 1}]
  }

  Timestamp instproc report {{string ""}} {
    foreach {start_diff last_diff} [my diffs] break
    my log "--$string (${start_diff}ms, diff ${last_diff}ms)"
  }

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

Timestamp t1


# # # # # # # # # # 
# # # # # # # # # #
# staging
# # # # # # # # # #
# # # # # # # # # #

namespace import -force ::xosoap::*
namespace import -force ::xosoap::marshaller::*
namespace import -force ::xosoap::visitor::*
namespace import -force ::xoexception::*
namespace import -force ::xosoap::exceptions::*
namespace import -force ::xorb::transport::*
namespace import -force ::xorb::*


# # # # # # # # # # 
# # # # # # # # # #
# helpers
# # # # # # # # # #
# # # # # # # # # #

# / / / / / / / / / / / / /

test case "xosoap test cases"

test section "SoapHttpListener"

set url http://localhost:8000/xosoap/services/Test

# # # # # # # # # # #
# missing SOAPAction
# header field

set r1 [::xo::HttpRequest new -url $url \
	    -content_type "text/xml" \
	    -post_data "<test></test>"]
# "Dispatching http request (missing SOAPAction header field)"
#ns_write "r1=[$r1 serialize]<br/>"
? {$r1 exists statusCode} 0 "Missing SOAPAction header field"

# # # # # # # # # # #
# missing post_data

?+ { set r1 [::xo::HttpRequest new -url $url \
		 -content_type "text/xml"\
		 -request_header_fields [list SOAPAction $url]]
} "Dispatching http request (missing post_data)"

#ns_log notice "r1=[$r1 serialize]"

? {$r1 set statusCode} 406 "Missing POST data"

# # # # # # # # # # #
# GET parameter other
# than wsdl

set url $url?m=view
?+ { set r1 [::xo::HttpRequest new -url $url \
		 -content_type "text/xml"\
		 -request_header_fields [list SOAPAction $url]]
} "Dispatching http request (wrong request parameter)"
? {$r1 set statusCode} 406 "Invalid request parameter"



# # # # # # # # # # # # # 
# # # # # # # # # # # # #
# # # # # # # # # # # # #
# # # # # # # # # # # # #

test section "Invocation Context"

namespace import -force ::xorb::context::*

# / / / / / / / / / / / / / / / / /
# create local invocation context

?+ {SoapInvocationContext require} "Requiring an invocation object"
? {::xotcl::Object isobject ::xo::cc} 1 \
    "Verifying existance of invocation context" 

test subsection "InvocationDataVisitor"

# / / / / / / / / / / / / / / / / /
# simulate scenario: InboundRequest

# clutter up the invocation object
::xo::cc marshalledRequest 1; # would be set by MessageHandler
::xo::cc unmarshalledRequest 1; # would be set by DeMarshallingInterceptor
?+ {set idv [InvocationDataVisitor new]} \
    "Initialising visitor (InboundRequest scenario)"
?++ {$idv scenario} \
    "::xosoap::visitor::InvocationDataVisitor::InboundRequest"\
    "Identifying scenario 'InboundRequest' (mixins: [$idv scenario])"

# / / / / / / / / / / / / / / / / /
# simulate scenario: OutboundResponse

# clutter up the invocation object
::xo::cc virtualCall 1; # would be set InvocationDataVisitor
::xo::cc virtualArgs 1; # would be set by InvocationDataVisitor
::xo::cc marshalledResponse {};
::xo::cc unmarshalledResponse {};
::xo::cc marshalledRequest 1; # would be set by MessageHandler
::xo::cc unmarshalledRequest 1; # would be set by DeMarshallingInterceptor

?+ {set idv [InvocationDataVisitor new]} \
    "Initialising visitor (OutboundResponse scenario)"
?++ {$idv scenario} \
    "::xosoap::visitor::InvocationDataVisitor::OutboundResponse"\
    "Identifying scenario 'OutboundResponse' (mixins: [$idv scenario])"


# / / / / / / / / / / / / / / / / /
# simulate scenario: OutboundRequest

# clutter up the invocation object
::xo::cc marshalledResponse {};
::xo::cc unmarshalledResponse {};
::xo::cc unmarshalledRequest {}; # would be set by MessageHandler
::xo::cc marshalledRequest {}; # would be set by DeMarshallingInterceptor
::xo::cc virtualCall 1; # would be set InvocationDataVisitor
::xo::cc virtualArgs 1; # would be set InvocationDataVisitor


?+ {set idv [InvocationDataVisitor new]} \
    "Initialising visitor (OutboundRequest scenario)"
?++ {$idv scenario} \
    "::xosoap::visitor::InvocationDataVisitor::OutboundRequest"\
    "Identifying scenario 'OutboundRequest' (mixins: [$idv scenario])"

# / / / / / / / / / / / / / / / / /
# simulate scenario: InboundResponse

# clutter up the invocation object
::xo::cc marshalledResponse 1;
::xo::cc unmarshalledResponse 1;
::xo::cc unmarshalledRequest 1; # would be set by MessageHandler
::xo::cc marshalledRequest 1; # would be set by DeMarshallingInterceptor
::xo::cc virtualCall 1; # would be set InvocationDataVisitor
::xo::cc virtualArgs 1; # would be set InvocationDataVisitor


?+ {set idv [InvocationDataVisitor new]} \
    "Initialising visitor (InboundResponse scenario)"
?++ {$idv scenario} \
    "::xosoap::visitor::InvocationDataVisitor::InboundResponse"\
    "Identifying scenario 'InboundResponse' (mixins: [$idv scenario])"

# / / / / / / / / / / / / / / / / /
# force an exception

# clutter up the invocation object

::xo::cc marshalledResponse {};
::xo::cc unmarshalledResponse {};
::xo::cc unmarshalledRequest {}; # would be set by MessageHandler
::xo::cc marshalledRequest {}; # would be set by DeMarshallingInterceptor
::xo::cc virtualCall {}; # would be set InvocationDataVisitor
::xo::cc virtualArgs {}; # would be set InvocationDataVisitor

?-- {set idv [InvocationDataVisitor new]} \
    "::xosoap::exceptions::Server::InvocationScenarioException"\
    "Initialising visitor from ambiguous invocation context"

# / / / / / / / / / / /
# cleanup

::xo::cc destroy

# # # # # # # # # # # # # 
# # # # # # # # # # # # #
# # # # # # # # # # # # #
# # # # # # # # # # # # #

test section "SOAP 1.1 marshalling"

set v [::xosoap::visitor::SoapMarshallerVisitor new] 

# / / / / / / / / / / / / / / / / /
# default request object

?+ { 
  set req [SoapEnvelope new -nest {
    ::xosoap::marshaller::SoapBodyRequest new \
	-elementName RemoteMethod \
	-targetMethod RemoteMethod
  }]
} "Creating a default SOAP 1.1 request object"



# / / / / / / / / / / / / / / / / /
# marshalling default request object

$v releaseOn $req
set xml [[$v xmlDoc] asXML]
set verify {<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
    <SOAP-ENV:Body>
        <m:RemoteMethod xmlns:m="Some-URI"/>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
}

? {expr {$xml eq $verify}} 1 "Marshalling default SOAP 1.1 request (outbound)"

# / / / / / / / / / / / / / / / / /
# default response

?+ {
  set respV [InvocationDataVisitor new -volatile \
		-scenario OutboundResponse -batch "OUTPUT"]
} "Creating a default SOAP 1.1 response object"
$respV releaseOn $req
$v releaseOn $req
set xml [[$v xmlDoc] asXML]
set verified {<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
    <SOAP-ENV:Body>
        <m:RemoteMethodResponse xmlns:m="Some-URI">
            <RemoteMethodReturn>OUTPUT</RemoteMethodReturn>
        </m:RemoteMethodResponse>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
}

? {expr {$xml eq $verified}} 1 \
    "Marshalling default SOAP 1.1 response (outbound)"

#ns_write <pre>|[ad_quotehtml $xml]|</pre>
#ns_write <pre>|[ad_quotehtml $verified]|</pre>
# / / / / / / / / / / / / / / / / / / / / /
# creating a 'faulty' fault
# malformed call to SoapElement->registerNS

?-- { set fault [SoapEnvelope new -nest {
		 ::xosoap::marshaller::SoapFault new \
		     -faultcode "xosoap:Server.Test" \
		     -faultstring "This would be the class' doc." \
		     -detail "This would be the errorInfo."} \
		    -registerNS [list a]] } \
    ::xosoap::exceptions::Server::MalformedNamespaceDeclaration \
    "Creating a SOAP envelope containing a 'faulty' SoapFault"


# / / / / / / / / / / / / / / / / / / / / /
# creating a valid fault

?+ { set fault [SoapEnvelope new -nest {
		 ::xosoap::marshaller::SoapFault new \
		     -faultcode "xosoap:Server.Test" \
		     -faultstring "This would be the class' doc." \
		     -detail "This would be the errorInfo."}] } \
    "Creating a SOAP envelope containing a correct SoapFault"



$v releaseOn $fault
set xml [[$v xmlDoc] asXML]
set verified {<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
    <SOAP-ENV:Body>
        <SOAP-ENV:Fault xmlns:xosoap="urn:xotcl-soap">
            <faultcode>xosoap:Server.Test</faultcode>
            <faultstring>This would be the class' doc.</faultstring>
            <detail>This would be the errorInfo.</detail>
        </SOAP-ENV:Fault>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
}
? {expr {$xml eq $verified}} 1 "Marshalling default SOAP 1.1 FAULT (outbound)"

#ns_write <pre>|[ad_quotehtml $xml]|</pre>
#ns_write <pre>|[ad_quotehtml $verified]|</pre>
#ns_write "children: [$req children]<br/>"
#ns_write "soapelements: [SoapElement allinstances]<br/>"
#ns_write [::Serializer deepSerialize $req]

# # # # # # # # # # # # # 
# # # # # # # # # # # # #
# # # # # # # # # # # # #
# # # # # # # # # # # # #

test section "XS 1.0 datatypes validation"

test subsection "Simple Types"

namespace import -force ::xosoap::xsd::*

# # # # # # # # # # # # #
# xsd:string
set x xsd:string
set any [XsString new -set __value__ $x]
? {$any validate} 1 "xsd:string validation ('[$any set __value__]')"

# # # # # # # # # # # # #
# xsd:integer
set y 12345
set any [XsInteger new -set __value__ $y] 
? {$any validate} 1 "xsd:integer validation ('$y')"
$any set __value__ -$y
? {$any validate} 1 "signed xsd:integer (-) validation ('-$y')"
$any set __value__ +$y
? {$any validate} 1 "signed xsd:integer (+) validation ('+$y')"
$any set __value__ $x
? {$any validate} 0 "xsd:integer validation (true string negative: '$x')"
set x 1.12334
$any set __value__ $x
? {$any validate} 0 "xsd:integer validation (true decimal negative: '$x')"
set upper +4294967296
$any set __value__ $upper

? {$any validate} 0 "xsd:integer validation (true upper-bound negative: '$upper')"
set lower -4294967296
$any set __value__ $lower
? {$any validate} 0 "xsd:integer validation (true lower-bound negative: '$lower')"

# # # # # # # # # # # # #
# xsd:float
set xs [list 1.1234 {xsd:float validation ('$x')} \
	    -1E4 {xsd:float validation ('$x')} \
	    1267.43233E12 {xsd:float validation ('$x')} \
	    12.78e-2 {xsd:float validation ('$x')} \
	    12 {xsd:float validation ('$x')} \
	    -0 {xsd:float validation ('$x')} \
	    0 {xsd:float validation ('$x')} \
	    INF {xsd:float validation ('$x')} \
	    NaN {xsd:float validation ('$x')}]

set any [XsFloat new]
foreach {x msg} $xs {
  $any set __value__ $x
  eval ? "{$any validate}" 1 [subst [list $msg]] 
}

$any set __value__ 6.80564733842e+38
? {$any validate} 0 "xsd:float validaton (true upper-bound negative: '$x')"

# # # # # # # # # # # # #
# xsd:double
set xs [list 1.1234 {xsd:double validation ('$x')} \
	    -1E4 {xsd:double validation ('$x')} \
	    1267.43233E12 {xsd:double validation ('$x')} \
	    12.78e-2 {xsd:double validation ('$x')} \
	    12 {xsd:double validation ('$x')} \
	    -0 {xsd:double validation ('$x')} \
	    0 {xsd:double validation ('$x')} \
	    INF {xsd:double validation ('$x')} \
	    NaN {xsd:double validation ('$x')} \
	    6.80564733842e+38 {xsd:double validation ('$x')}]
set any [XsDouble new]
foreach {x msg} $xs {
  $any set __value__ $x
  eval ? "{$any validate}" 1 [subst [list $msg]] 
}

# # # # # # # # # # # # #
# xsd:boolean

set xs [list 0 {xsd:boolean validation ('$x')} \
	    1 {xsd:boolean validation ('$x')} \
	    true {xsd:boolean validation ('$x')} \
	    false {xsd:boolean validation ('$x')}]
set any [XsBoolean new]
foreach {x msg} $xs {
  $any set __value__ $x
  eval ? "{$any validate}" 1 [subst [list $msg]] 
}

# # # # # # # # # # # # #
# xsd:decimal

set xs [list 1.1234 {xsd:decimal validation ('$x')} \
	    12 {xsd:decimal validation ('$x')} \
	    -0 {xsd:decimal validation ('$x')} \
	    0 {xsd:decimal validation ('$x')}]

set any [XsDecimal new]
foreach {x msg} $xs {
  $any set __value__ $x
  eval ? "{$any validate}" 1 [subst [list $msg]] 
}

$any set __value__ xsd:decimal
? {$any validate} 0 "xsd:decimal validation (true string negative: '$x')"
$any set __value__ -1E4
? {$any validate} 0 "xsd:decimal validation (true sic'ish float negative: '$x')"
$any set __value__ 1267.43233E12
? {$any validate} 0 "xsd:decimal validation (true sic'ish float negative: '$x')"

# # # # # # # # # # # # #
# xsd:base64Binary

set x {SMOkdHRlbiBIw7x0ZSBlaW4gw58gaW0gTmFtZW4sIHfDpHJlbiBzaWUgbcO2Z2xpY2hlcndlaXNlIGtlaW5lIEjDvHRlIG1laHIsDQpzb25kZXJuIEjDvMOfZS4NCg==}
set any [XsBase64Binary new]
$any set __value__ $x
? {$any validate} 1 "xsd:base64Binary validation"
set x {SMOkdHRlbiBIw7x0ZSBlaW4gw58gaW0gTmFtZW4sIHfDpHJlbiBzaWUgbcO2Z2xpY2hlcndlaXNlIGtlaW5lIEjDvHRlIG1laHIsDQpzb25kZXJuIEjDvMOfZS4N&?==}
$any set __value__ $x
? {$any validate} 0 "xsd:base64Binary validation (true &? char negative)"

# # # # # # # # # # # # #
# xsd:hexBinary

set x {4992961d}
set any [XsHexBinary new]
$any set __value__ $x
? {$any validate} 1 "xsd:hexBinary validation"
set x {499%%961d}
$any set __value__ $x
? {$any validate} 0 "xsd:hexBinary validation (true %% char negative)"

# # # # # # # # # # # # #
# xsd:dateTime
set any [XsDateTime new]
set x 2002-10-10T12:00:00-05:00 
$any set __value__ $x
? {$any validate} 1 "xsd:dateTime validation ('$x')"
set x 2002-10-10T17:00:00Z
$any set __value__ $x
? {$any validate} 1 "xsd:dateTime validation ('$x')"
set x 2002-10-10T12:00:00Z
$any set __value__ $x
? {$any validate} 1 "xsd:dateTime validation ('$x')"
set x 2002-10-10T12:00:00
$any set __value__ $x
? {$any validate} 1 "xsd:dateTime validation ('$x')"

set x 2002-10-10D12:00:00Z
$any set __value__ $x
? {$any validate} 0 "xsd:dateTime validation (true T->D char negative)"
set x 2002-10-10T12:00:00+15:00
$any set __value__ $x
? {$any validate} 0 "xsd:dateTime validation (true time-zone negative)"
set x 2002-10-10
$any set __value__ $x
? {$any validate} 0 "xsd:dateTime validation (true only-date negative)"
set x 12:00:00
$any set __value__ $x
? {$any validate} 0 "xsd:dateTime validation (true only-time negative)"

# # # # # # # # # # # # #
# xsd:date

set any [XsDate new]
set x 2002-10-10
$any set __value__ $x
? {$any validate} 1 "xsd:date validation ('$x')"

set x 2002-10-10Z
$any set __value__ $x
? {$any validate} 1 "xsd:date validation ('$x')"

set x 2002-10-10-05:00
$any set __value__ $x
? {$any validate} 1 "xsd:date validation ('$x')"

set x 2002-10-10T
$any set __value__ $x
? {$any validate} 0 "xsd:date validation (true T-plus negative)"

# # # # # # # # # # # # #
# xsd:time

set any [XsTime new]
set x 12:00:00
$any set __value__ $x
? {$any validate} 1 "xsd:time validation ('$x')"

set x 12:00:00Z
$any set __value__ $x
? {$any validate} 1 "xsd:time validation ('$x')"

set x 12:00:00+02:00
$any set __value__ $x
? {$any validate} 1 "xsd:time validation ('$x')"

set x 25:00:00
$any set __value__ $x
? {$any validate} 0 "xsd:time validation (true extra-hour negative)"



ns_write "<p>
<hr>
 Tests passed: [test set passed]<br>
 Tests failed: [test set failed]<br>
 Tests Time: [t1 diff -start]ms<br>
"