ad_page_contract {

    @author Neophytos Demetriou
    @author Stefan Sobernig
} {
    {q:trim,notnull "beneath the wheel"}
}

set schema http://www.w3.org/2001/XMLSchema

set registry ""
for {set i 0} {$i < 10} {incr i} {
    set endpoint "http://localhost:8000/xosoap/services/SqiService${i}"
    lappend registry $endpoint 

    set methodName synchronousQuery
    set cmdName SqiService${i}.${methodName}

    set procName $methodName
    set uri "urn:xmethods-getPoem"
    set proxy $endpoint
    set params { statement string }
    set schema [list xsd $schema]
    set encoding http://schemas.xmlsoap.org/soap/encoding/
    set transport ""
    set action ""
    set wrapProc ""
    set replyProc ""
    set parseProc ""
    set postProc ""
    set command ""
    set errorCommand ""
    set headers ""
    set schemas ""
    set version ""


	SOAP::create $cmdName \
	    -name $procName \
	    -uri $uri \
	    -proxy $proxy \
	    -params $params \
	    -transport $transport \
	    -action $action \
	    -wrapProc $wrapProc \
	    -replyProc $replyProc \
	    -parseProc $parseProc \
	    -postProc $postProc \
	    -command $command \
	    -errorCommand $errorCommand \
	    -httpheaders $headers \
	    -schemas $schemas \
	    -version $version \
	    -encoding $encoding 


    lappend result "sqi service $i: [$cmdName $q]"

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
