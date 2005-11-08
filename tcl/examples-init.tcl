namespace eval services {

########################################################################
# 	A simple echo service example (aka "Gertrude Stein's Echo")
#		* Exposes "getPoem" as remote method
#		* "non_visible_proc" and "init" are declared hoarded, i.e. they
#		are not visible/ invokable via xoSoap.
#		* the service is offered in a per-request manner (lifecycle parameter
#		set to "0", if set to "1" it is exposed as static instance)
########################################################################

::xosoap::Service Poem -hoard [list init] -lifecycle 1

	Poem instproc init {} {
	
		my set result "Rose"		
	
	}

    Poem instproc getPoem {statement} {
    
    
    my instvar result

	append result " $statement"	
	
	return $result
	
    }    
    
########################################################################
#	A simple service example (inspired by a SQI use case)
#		* it listens both at the request and response flow of handlers.
#		* provides for simple logging to logs/error.log
########################################################################

::xosoap::Interceptor LoggingInterceptor -superclass {::xosoap::RequestInterceptor ::xosoap::ResponseInterceptor}
LoggingInterceptor instproc handleRequest args {
	
	
	set request [next]
	my log "request1: [lindex $args 0]"	
	#return $request
}
LoggingInterceptor instproc handleResponse args {
		
	my log "response1: $args"
	next [lindex $args 0]

}

::xosoap::Interceptor LoggingInterceptor2 -superclass ::xosoap::ResponseInterceptor

LoggingInterceptor2 instproc handleResponse args {
		
	my log "response2: $args"
	next [lindex $args 0]

}

::xosoap::Interceptor LoggingInterceptor3 -superclass ::xosoap::RequestInterceptor

LoggingInterceptor3 instproc handleRequest args {
		
set request [next]
	my log "request3: [lindex $args 0]"	

}

}
