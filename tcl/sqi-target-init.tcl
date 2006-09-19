
namespace eval services {

    for {set i 0} {$i < 10} {incr i} {
	::xorb::service::InstantService SqiService${i} -package "SqiService${i}-package"
	SqiService${i} ad_instproc init {} {} {
	    #do nothing
	} 
	

	# -targetSessionID:string 
	# -startResult:string 
	SqiService${i} ad_instproc -operation synchronousQuery {
	    -queryStatement:string 
	    args
	} {
	    #description
	} {

	    my log "Invocation call does work."
	    #my instvar result	
	    #return [append result " $statement"]

	    return "reply from [self] for $queryStatement is [expr {rand()}]"
	}

    }

	# # # # # # # # # # # # # # # # # # # # #
	# # # # # # # # # # # # # # # # # # # # # 
	
	::xorb::aux::Dict firstCustomType {
		intValue:integer
		floatValue:double
		stringValue:string
	}
	
	::xorb::aux::Dict secondCustomType {
		dictValue:firstCustomType
		strValue:string
	}  

	::xorb::service::InstantService ComplexSqiService -package xosoap
	
	ComplexSqiService ad_instproc -operation synchronousQuery {
	    -queryStatement:integer(2)
	} {
	    #description
	} {

	    my log "Invocation call involving complex data types does work."
	    #my instvar result	
	    #return [append result " $statement"]
		array set tmpArray $queryStatement
	    return "reply from [self] for '$queryStatement' is of size: [array size tmpArray]"
	}
}