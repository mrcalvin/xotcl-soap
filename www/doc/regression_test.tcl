# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# +-+-+-+-+-+-+ +-+-+-+-+ +-+-+-+-+-+
# |x|o|s|o|a|p| |t|e|s|t| |s|u|i|t|e|
# +-+-+-+-+-+-+ +-+-+-+-+ +-+-+-+-+-+
# author: stefan.sobernig@wu-wien.a.at
# cvs-id: $Id: xorb-aux-procs.tcl 10 2006-07-21 15:57:15Z ssoberni $
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

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

test case "xosoap test cases"

test section "Basic Setup"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# ((title)) 			XOTcl version test
# ((description)) 	Verifies whether the adequate XOTcl version is installed: >1.4
# ((type)) 			Basic Setup
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

? {expr {$::xotcl::version < 1.4}} 0 "XOTcl Version $::xotcl::version >= 1.4"


test section "Soap Argument Parsing"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# ((title)) 			Parsing for SOAP encoded arguments (server-inbound,client-inbound)
# ((description)) 	Processes a suite of SOAP-encoded (1.1) types, partly taken from 
# ((type)) 			SOAP Parsing
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

test subsection "SOAP Arrays"
namespace import ::xorb::aux::*
proc parse {soap} {

	set pre {<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance">
    <SOAP-ENV:Body>
        <ns:synchronousQuery xmlns:ns="urn:xmethods-synchronousQuery">}
        
     set post {
     				</ns:synchronousQuery>
    				</SOAP-ENV:Body>
			</SOAP-ENV:Envelope>}
			
	set x [::xosoap::marshaller::Argument new -domNode [[[[dom parse  "$pre$soap$post"] documentElement] getElementsByTagName *synchronousQuery] firstChild]]
	return [$x rollOut]
}

# //////////////////////////////////////////////////////////
set soapenc {
	<myFavoriteNumbers SOAP-ENC:arrayType="xsd:int[2]">
   		<number>3</number>
   		<number>4</number>
	</myFavoriteNumbers>}


set x [Array new -name "myFavoriteNumbers" -type integer -occurrence 2 -contains {
	::xorb::aux::Integer new -name "number" -detainee 3
	::xorb::aux::Integer new -name "number" -detainee 4
}] 
	

? {string equal [parse $soapenc] [$x getValue]} 1 "Attribute-wise parsing (SOAP-ENC:arrayType)."

# //////////////////////////////////////////////////////////
set soapenc {
	<SOAP-ENC:Array SOAP-ENC:arrayType="xsd:int[2]">
   		<SOAP-ENC:int>3</SOAP-ENC:int>
   		<SOAP-ENC:int>4</SOAP-ENC:int>
	</SOAP-ENC:Array>}
	
? {string equal [parse $soapenc] [$x getValue]} 1 "Element-wise parsing (SOAP-ENC:Array + SOAP-ENC:arrayType)."

# //////////////////////////////////////////////////////////
set soapenc {
	<myFavoriteNumbers SOAP-ENC:arrayType="xsd:int[2]" xsi:type="SOAP-ENC:Array">
   		<number>3</number>
   		<number>4</number>
	</myFavoriteNumbers>}
	
? {string equal [parse $soapenc] [$x getValue]} 1 "Attribute-wise parsing (xsi:type='SOAP-ENC:Array' + SOAP-ENC:arrayType)."

# //////////////////////////////////////////////////////////
set soapenc {
	<myFavoriteNumbers SOAP-ENC:arrayType="xsd:ur-type[2]">
   		<number xsi:type="xsd:int">3</number>
   		<number xsi:type="xsd:int">4</number>
	</myFavoriteNumbers>}
	
? {string equal [parse $soapenc] [$x getValue]} 1 "ur-type support (1): xsi:type given in sub-elements, SINGLE atom type."

# //////////////////////////////////////////////////////////
set soapenc {
	<myFavoriteNumbers SOAP-ENC:arrayType="xsd:ur-type[2]">
   		<SOAP-ENC:int>3</SOAP-ENC:int>
   		<SOAP-ENC:int>4</SOAP-ENC:int>
	</myFavoriteNumbers>}
	
? {string equal [parse $soapenc] [$x getValue]} 1 "ur-type support (1a): SINGLE atom type, element-wise type encoding."

# //////////////////////////////////////////////////////////
set soapenc {
	<myFavoriteNumbers SOAP-ENC:arrayType="xsd:ur-type[2]">
   		<number xsi:type="xsd:int">3</number>
   		<number xsi:type="xsd:string">4</number>
	</myFavoriteNumbers>}
	
? {string equal [parse $soapenc] [$x getValue]} 1 "ur-type support (2): xsi:type given in sub-elements, MIXED atom type."

# //////////////////////////////////////////////////////////
set soapenc {
	<myFavoriteNumbers SOAP-ENC:arrayType="xsd:ur-type[2]">
   		<SOAP-ENC:string>myString</SOAP-ENC:string>
   		<SOAP-ENC:int>4</SOAP-ENC:int>
	</myFavoriteNumbers>}
	
set x [Array new -name "myFavoriteNumbers" -type integer -occurrence 2 -contains {
	::xorb::aux::String new -name "number" -detainee "myString"
	::xorb::aux::Integer new -name "number" -detainee 4
}] 

? {string equal [parse $soapenc] [$x getValue]} 1 "ur-type support (2): MIXED atom type, element-wise type encoding."



# //////////////////////////////////////////////////////////
set soapenc {
	<myFavoriteNumbers SOAP-ENC:arrayType="xsd:int[2]">
   		<number xsi:type="xsd:int">3</number>
   		<number xsi:type="xsd:string">4</number>
	</myFavoriteNumbers>}

	
? {catch {[parse $soapenc]}} 1 "Order of predence (typing) xsi:type given in sub-elements, violating compound type."

# //////////////////////////////////////////////////////////
set soapenc {
	<myFavoriteNumbers SOAP-ENC:arrayType="xsd:ur-type[2]">
   		<number>3</number>
   		<number>4</number>
	</myFavoriteNumbers>}
	
? {catch {[parse $soapenc]} msg} 1 "Order of predence (typing), xsi:type NOT given in sub-elements, violating typing requirement."



ns_write "<p>
<hr>
 Tests passed: [test set passed]<br>
 Tests failed: [test set failed]<br>
 Tests Time: [t1 diff -start]ms<br>
" 