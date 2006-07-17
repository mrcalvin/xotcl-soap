ad_page_contract {

    @author Neophytos Demetriou
    @author Stefan Sobernig
} {
    {q:trim,notnull "beneath the wheel"}
}


set schema http://www.w3.org/2001/XMLSchema

set registry ""
for {set i 0} {$i < 10} {incr i} {
    set endpoint "http://localhost:8070/xosoap/services/SqiService${i}"
    lappend registry $endpoint 

    set methodName synchronousQuery
    set className SqiService${i}.${methodName}

    Class $className -mixin xosoap::Client

    $className ad_instproc \
	-uri "urn:xmethods-getPoem" \
	-proxy $endpoint \
	-schemas [list xsd $schema] \
	-encoding http://schemas.xmlsoap.org/soap/encoding/ \
	$methodName \
	{-queryStatement:remote limit} \
	{this is a test} \
	{ 

	    return [next [lrange $queryStatement 0 $limit]]
	}

    set o [$className new]
    lappend result "sqi service $i: [$o synchronousQuery -queryStatement $q 1]"

}


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
