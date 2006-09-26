#package req SOAP

set endpoint "http://localhost:8000/xosoap/services/ComplexSqiService"
set schema http://www.w3.org/2001/XMLSchema

namespace import -force ::rpcvar::typedef

typedef {
   intValue    int
   floatValue  float
   stringValue string
} simpleStruct

SOAP::create synchronousQuery \
    -uri "urn:xmethods-synchronousQuery" \
    -proxy $endpoint \
    -params { queryStatement int(2) } \
    -schema [list xsd $schema] \
    -encoding http://schemas.xmlsoap.org/soap/encoding/


set result [::template::synchronousQuery [list 0 300 1 400]]

set procVarName ::SOAP::_template_synchronousQuery
foreach name     [array names $procVarName] {
    lappend procVarNameArr "$name=[set ${procVarName}($name)]"
}

ns_log notice $result
doc_return 200 text/html [subst {
<html>
<body>
 "===================="
    $result
 "===================="



<pre>
    [ad_quotehtml [::SOAP::dump ::template::synchronousQuery]]

    procVarNameArr=[join $procVarNameArr \n]
</pre>
</body>
</html>
}]
