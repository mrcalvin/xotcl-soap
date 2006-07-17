#package req SOAP

set endpoint "http://localhost:8070/xosoap/services/Poem"
set schema http://www.w3.org/2001/XMLSchema

SOAP::create getPoem \
    -uri "urn:xmethods-getPoem" \
    -proxy $endpoint \
    -params { statement string } \
    -schema [list xsd $schema] \
    -encoding http://schemas.xmlsoap.org/soap/encoding/


set result [::template::getPoem "is a rose"]

set procVarName ::SOAP::_template_getPoem
foreach name     [array names $procVarName] {
    lappend procVarNameArr "$name=[set ${procVarName}($name)]"
}


doc_return 200 text/html [subst {
<html>
<body>
 "===================="
    $result
 "===================="



<pre>
    [ad_quotehtml [::SOAP::dump ::template::getPoem]]

    procVarNameArr=[join $procVarNameArr \n]
</pre>
</body>
</html>
}]
