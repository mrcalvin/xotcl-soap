
namespace eval services {

########################################################################
# 	A simple echo service example (aka "Gertrude Stein's Echo")
#		* Exposes "getPoem" as remote method
#		* "non_visible_proc" and "init" are declared hoarded, i.e. they
#		are not visible/ invokable via xoSoap.
#		* the service is offered in a per-request manner (lifecycle parameter
#		set to "0", if set to "1" it is exposed as static instance)
########################################################################


::xorb::service::InstantService Poem 
Poem ad_instproc init {} {} {

	my set result "Rose"

} 

Poem ad_instproc -operation getPoem {-statement:string args} {A poem writing service} {

	my log "Invocation call does work."
	my instvar result	
	return [append result " $statement"]
	

} 


#::xosoap::Service Poem -hoard [list init] -lifecycle 1
#
#	Poem instproc init {} {
#	
#		my set result "Rose"		
#	
#	}
#
#   Poem instproc getPoem {statement} {
#    
#    
#    my instvar result
#
#	append result " $statement"	
#	
#	return $result
#	
#    }    
    
########################################################################
#	A simple service example (inspired by a SQI use case)
#		* it listens both at the request and response flow of handlers.
#		* provides for simple logging to logs/error.log
########################################################################

::xosoap::Interceptor LoggingInterceptor -scope 0 -superclass {::xosoap::RequestInterceptor ::xosoap::ResponseInterceptor}
LoggingInterceptor instproc handleRequest args {
	
	# 1) retrieve args
	my log "AppScoped Request1 bekommt args: [lindex $args 1]"
	# 2) modify args
	
	# 3) pass on args or return
	next [lindex $args 0] [lindex $args 1] 
	#return "ns_return 200 text/plain {Alles ok}"
	
	
	}
LoggingInterceptor instproc handleResponse args {
		
	my log "AppScoped response1: $args"
	next [lindex $args 0]

}


#::xosoap::Interceptor LoggingInterceptor2 -superclass ::xosoap::ResponseInterceptor

#LoggingInterceptor2 instproc handleResponse args {
		
#	my log "response2: $args"
#	next [lindex $args 0]

#}

#::xosoap::Interceptor LoggingInterceptor3 -superclass ::xosoap::RequestInterceptor

#LoggingInterceptor3 instproc handleRequest args {
		
#set request [next]
#	my log "request3: [lindex $args 0]"	

#}

}
