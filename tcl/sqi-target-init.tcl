
namespace eval services {

    for {set i 0} {$i < 10} {incr i} {
	::xorb::service::InstantService SqiService${i}
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

}