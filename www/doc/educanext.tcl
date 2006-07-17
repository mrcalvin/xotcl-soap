ad_page_contract {

    @author Neophytos Demetriou
    @author Stefan Sobernig

} {
    {q:trim,notnull "beneath the wheel"}
}


set schema http://www.w3.org/2001/XMLSchema
set endpoint "http://educanext.dit.upm.es:8000/services/TargetService"

set methodName synchronousQuery
set className Educanext

Class $className -mixin xosoap::Client

$className ad_instproc \
    -action $endpoint \
    -uri "urn:xmethods-getPoem" \
    -proxy $endpoint \
    -schemas [list xsd $schema] \
    -encoding http://schemas.xmlsoap.org/soap/encoding/ \
    $methodName \
    {-targetSessionID:remote -queryStatement:remote -startResult:remote} \
    {this is a test} \
    {
	return [next 123 <simpleQuery>\n\n<term>$queryStatement</term></simpleQuery> 1]
    }

set o [$className new -volatile]
lappend result "sqi service educanext: [$o synchronousQuery -queryStatement $q]"




doc_return 200 text/html [subst {
<pre>
[join $result \n]
</pre>
}]


return

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
