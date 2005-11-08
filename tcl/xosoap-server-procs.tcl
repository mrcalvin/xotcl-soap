####################################################
# Soap Message Handler
# 
# to-dos:
#			*  	handler chain (Logging- & Caching Handler) [done]
#			*	client-dependent ro [open]
#			*	error handling [done]
#			*	place error handlers in code ...
#			* 	life cycle manager [done]
#			* 	per-request instances > pooling [done]
#			* 	static instances > lazy acquisition [done]
#
#   @param
#   @see
#   @author
#   @creation-date
#   @return
#   @error
#
# 
####################################################


ad_library {
   
    <p>Library providing basic xoSoap facilities:</p>
    <p>
    <ul>
    	<li>RequestMessageHandler: provides a filter for request processing, a pre-authentication hook and basic (SOAP) message delivery</li>
    	<li>Interceptor: provides an extensible chain of request/response handlers</li>
    	<li>Invoker: allows registration of new services and moderates the entire invocation process of remote objects</li>
    	<li>Service: a prototype for services to be hosted by xoSoap</li>
    	<li>Exception: introduces basic exception handling and a XML-flavoured error format</li>   	
    </ul>
    </p>
    

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August 18, 2005
    @cvs-id $Id$

  
}


namespace eval xosoap {}


 
####################################################
# Request Message Handler
####################################################

::xotcl::Object xosoap::RequestMessageHandler -ad_doc {
    

     <p>The object xosoap::RequestMessageHandler implements the Server Request
     Handler pattern. It aims at ...<p>
     <p>
     <ul>
      <li>... hosting a pre-authentication filter that is registered with the request processor to intercept POST requests targeting xosoap's subsite (see xosoap-init.tcl)</li>
      <li>... hosting a request processor procedure a POST request and its SOAP payload is redirected to after successful authentication. It therefore provides handling of SOAP messages: receiving/forwarding incoming (preprocessRequest/handleRequest; see xosoap-init.tcl) and
     delivering outgoing SOAP messages (handleResponse)</li>
     </ul>
	</p>
     
     
	 @author stefan.sobernig@wu-wien.ac.at
	 @creation-date August 18, 2005 
     
 }										
										

::xosoap::RequestMessageHandler ad_proc init {} {
	
	Upon intialisation, some credentials are prepared and made instance variables. 
    They will later be used to populate a connection object.
	
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August 18, 2005
	
      
    @see xosoap::RequestMessageHandler::preauth


} {

    my set user_id "" 
    my set url ""
    my set urlv "" 
    #my set user {stefan.sobernig@wu-wien.ac.at} 
    #my set password "asasas"

	my set user "" 
    my set password ""


    # default config settings

    my set package_prefix "xosoap"
    my set service_prefix "services"

    }

::xosoap::RequestMessageHandler ad_proc preauth {} {

	The method serves as pre-authentication filter hooked into the request processor flow (ns_register_filter; see xosoap-init.tcl).
	HTTP POST requests that target the xosoap subsite are redirected and processed by this filter method. It clears the current 	
	connection object and, after successful authentication, populates a new one. (Note: Authentication is currently not handled at the level of HTTP but delegated to SOAP, in other words, requesting clients will -- by default -- be authenticated as anonymous / guest users. Authentication & authorization credentials would therefore be submitted in the SOAP-ENV:Header element of the request message and the task to verify these against respective permission settings of a subsite / package is to be taken care of when developing services.)
	
    @author stefan.sobernig@wu-wien.ac.at
	@creation-date August 18, 2005
		
} {
    my init

    my instvar user_id url urlv user password
	
    ad_conn -reset

    set url [ns_urldecode [ns_conn url]]
    set urlv [ns_conn urlv]
    
    array set auth [auth::authenticate -username $user -password $password]
    #my log "\[xoSoap\] auth status $auth(auth_status)"
    if { [string equal $auth(auth_status) "ok"] } {
    ad_conn -set user_id $auth(user_id)
    set user_id $auth(user_id)
								
    #my log "\[xoSoap\] user_id: $user_id url: $url urlv:
    #$urlv user: $user pwd: $password"
    
    return filter_ok;
    } else {
    
	 #my log "\[xoSoap\] authentication failed: $auth(auth_status)."
	 #return filter_return;
	 ad_conn -set user_id 0
	 ad_conn -set untrusted_user_id 0
	 return filter_ok;

    }
}

::xosoap::RequestMessageHandler ad_proc handleRequest args  {

	A call on this method initiates the processing for the chain of request handlers.
	As default endpoint of the request flow, the <a href='/xotcl/show-object?object=::xosoap::InvocationInterceptor'>::xosoap::InvocationInterceptor</a> mixin class provides 
	forwarding of the call to the actual Invoker thread.
	
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October 14, 2005
	
	@param args (0):contains the service name as extracted from the retrieved URL<br>(1): contains the SOAP payload of the HTTP POST request 
	
	@see <a href='/api-doc/proc-view?proc=::xosoap::RequestInterceptor+abstract+instproc+handleRequest'>::xosoap::RequestInterceptor abstract handleRequest</a>
	@see <a href='/api-doc/proc-view?proc=::xosoap::InvocationInterceptor+instproc+handleRequest'>::xosoap::InvocationInterceptor handleRequest</a>
} {}

::xosoap::RequestMessageHandler ad_proc handleResponse args  {

	The method is the endpoint operation of the response handler chain that is triggered
	by the <a href='/xotcl/show-object?object=::xosoap::InvocationInterceptor'>::xosoap::InvocationInterceptor</a>
	after invocation finished. 
	
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October 14, 2005
	
	
	@param args (0): The final ns_return command as generated by the Invoker, including http state code and the SOAP response payload.
		
	@see <a href='/api-doc/proc-view?proc=::xosoap::ResponseInterceptor+abstract+instproc+handleResponse'>::xosoap::ResponseInterceptor handleResponse</a>
	
} {
	
	# handler chain or response flow cast result command as multiple embedded list element
	
	eval [lindex $args 0]
}

::xosoap::RequestMessageHandler ad_proc preprocessRequest {} {

	The method is registered as post-authentication "request processor procedure" (ns_register_proc; see xosoap-init.tcl).
	HTTP POST requests that target the xosoap subsite are redirected and processed by this method. It decomposes the received
	resource locator, checks the validity of the latter, finally extracts the SOAP payload and passes it to the handler chain 
	(handleRequest) Validity refers to locators that indicate a subsite depth of 3 maximum and have the following form: 
	/xosoap/services/<NameOfService>. Invalid locators result in an HTTP 403 response.	
	
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August 18, 2005
	
	
	@see <a href='/api-doc/proc-view?proc=::xosoap::RequestInterceptor+abstract+instproc+handleRequest'>::xosoap::RequestInterceptor abstract handleRequest</a>
	@see ns_register_proc
	
	
} {
    my instvar user_id url urlv user password 
    									

    my debug "urlv length: [llength [my set urlv]]"
    if {[llength [my set urlv]] != 3} {
	ns_return 403 text/plain "Soap service endpoints exclusively reside at /[my set package_prefix]/[my set service_prefix]/<service_name>"
    } else {
	
	if {![string equal [lindex [my set urlv] 1] [my set service_prefix]]} {
	    	ns_return 403 text/plain "Soap service endpoints exclusively reside at /[my set package_prefix]/[my set service_prefix]/<service_name>"
	} else {
	    
	    set serviceName [lindex [my set urlv] 2]
	    set soap [ns_conn content]
	    my handleRequest $soap $serviceName
	}
   }
}

####################################################
# Interceptor (Meta-)Class
####################################################


::xotcl::Class xosoap::Interceptor -superclass ::xotcl::Class -ad_doc {

		<p>The meta-class xosoap::Interceptor implements a skeleton for request and/ or reponse handlers.
	     While the actual handler chain is realized by using XOTcl's mixin interception technique, i.e. 
	     interceptors/ handlers are classes that are mixed into <a href='/xotcl/show-object?object=xosoap::RequestMessageHandler'>xosoap::RequestMessageHandler</a>, this meta-class takes explicitly care
	     of registering interceptors/ handlers upon their declaration. Therefore, it mangles the list of mixin classes
	     attached to <a href='/xotcl/show-object?object=xosoap::RequestMessageHandler'>xosoap::RequestMessageHandler</a>
	     in several ways (see corresponding init method for more details).</p>
	     

		@author stefan.sobernig@wu-wien.ac.at
	 	@creation-date October 10, 2005     

	     
}

::xosoap::Interceptor ad_instproc init {} {

	<p>The method provides the actual registration logic for interceptor classes created by using the meta-class <a href='/xotcl/show-object?object=xosoap::Interceptor'>xosoap::Interceptor</a>:</p>
	<p>
	     	<ul>
	     	<li>First, upon initialisation it ascertains that the "built-in" interceptor <a href='/xotcl/show-object?object=xosoap::InvocationInterceptor'>xosoap::InvocationInterceptor</a> always ranks first in the mixin list. In other words, that <a href='/xotcl/show-object?object=xosoap::InvocationInterceptor'>xosoap::InvocationInterceptor</a> is always enforced first on the response track and processed last in the request flow of handlers.</li> 
	     	<li>Newly created handlers must be positioned in the mixin list according to their type: Interceptors of the type <a href='/xotcl/show-object?object=xosoap::RequestInterceptor'>xosoap::RequestInterceptor</a> are placed on top of the mixin list in order to have interceptors declared last to be called last. Note that "on top" means relatively to <a href='/xotcl/show-object?object=xosoap::InvocationInterceptor'>xosoap::InvocationInterceptor</a> that is always the sticky top endpoint of the chain. In contrast, interceptors of type <a href='/xotcl/show-object?object=xosoap::ResponseInterceptor'>xosoap::ResponseInterceptor</a> are appended to the end of the mixin list so that response interceptors declared last are called last in the response flow.</li>
	     	</ul>
	     </p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October 10, 2005 
	
	 
 		@see <a href='/xotcl/show-object?object=::xosoap::InvocationInterceptor'>::xosoap::InvocationInterceptor</a>
 		@see <a href='/xotcl/show-object?object=::xosoap::RequestInterceptor'>::xosoap::RequestInterceptor</a>
		@see <a href='/xotcl/show-object?object=::xosoap::ResponseInterceptor'>::xosoap::ResponseInterceptor</a>
		@see <a href='/xotcl/show-object?object=::xosoap::RequestMessageHandler'>::xosoap::RequestMessageHandler</a>

} {

	# Interceptors to be inserted into the request flow are added "on front"
	if { [[self] info superclass "::xosoap::RequestInterceptor"]  } {
	
			::xosoap::RequestMessageHandler mixin add [self]
			
			# make InvocationInterceptor a sticky bit in the request flow
			
			if { ![string equal [self] "::xosoap::InvocationInterceptor"]  &&  ![string equal [lsearch [::xosoap::RequestMessageHandler info mixin] "::xosoap::InvocationInterceptor"] "-1"] } { 
					#my log "[self] ... will now delete InvocationInterceptor"
					::xosoap::RequestMessageHandler mixin delete ::xosoap::InvocationInterceptor 
				}
			
			::xosoap::RequestMessageHandler mixin add ::xosoap::InvocationInterceptor 0
			
			
	} else {
	# Interceptors to be inserted into the response flow are added to the end of the mixin list
			::xosoap::RequestMessageHandler mixin add [self] end
	
	}
	
	my log "MixinList: [::xosoap::RequestMessageHandler info mixin]"
	
		
}

::xotcl::Class xosoap::RequestInterceptor -ad_doc {

	<p>The class hosts an abstract method that is required to be implemented by interceptors that are meant to listen on the request flow in the chain of interceptors. Interceptors can both participate in the request and response flow with the latter requiring the implementation of <a href='/xotcl/show-object?object=xosoap::ResponseInterceptor'>xosoap::ResponseInterceptor</a>.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October 10, 2005 
	
	}
::xosoap::RequestInterceptor abstract instproc handleRequest args 

::xotcl::Class xosoap::ResponseInterceptor -ad_doc {

	
	<p>The class hosts an abstract method that is required to be implemented by interceptors that are meant to listen on the response flow in the chain of interceptors. Interceptors can both participate in the response and request flow with the latter requiring the implementation of <a href='/xotcl/show-object?object=xosoap::RequestInterceptor'>xosoap::RequestInterceptor</a>.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October 10, 2005 
	
}
::xosoap::ResponseInterceptor abstract instproc handleResponse args

# defining and hooking-in the chain sibling of the RequestMessageHandler object (InvocationInterceptor)

::xosoap::Interceptor xosoap::InvocationInterceptor -superclass ::xosoap::RequestInterceptor -ad_doc {

		<p>The class defines a specific built-in interceptor that is made sticky on top of the chain of interceptors attached to <a href='/xotcl/show-object?object=xosoap::RequestMessageHandler'>xosoap::RequestMessageHandler</a>. It solely listens on the request track within the chain of interceptors and processes requests last.</p>
	

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October 12, 2005 
	
}
::xosoap::InvocationInterceptor ad_instproc handleRequest args {
		
			<p>It is reponsible for forwarding the request and the arguments therein, i.e. the name of the service and the SOAP payload, to the Invoker thread. Finally, after incovation suceeded, it calls the handleResponse method of <a href='/xotcl/show-object?object=xosoap::RequestMessageHandler'>xosoap::RequestMessageHandler</a> to initialise the response flow.</p>
		
		
		@author stefan.sobernig@wu-wien.ac.at
		@creation-date October 12, 2005 
		
			@param args (0):contains the service name as extracted from the retrieved URL<br>(1): contains the SOAP payload of the HTTP POST request 
	
	@see <a href='/xotcl/show-proc?proc=::xosoap::RequestInterceptor+abstract+instproc+handleRequest'>::xosoap::RequestInterceptor abstract handleRequest</a>
	@see <a href='/api-doc/proc-view?proc=::xosoap::RequestMessageHandler+instproc+handleRequest'>::xosoap::RequestMessageHandler handleRequest</a>

} {
		
	next
	set benchmark [time {::xosoap::RequestMessageHandler handleResponse [::xosoap::tsfInvoker do Invoker invoke [lindex $args 0] [lindex $args 1]]}]
	my debug "It took me $benchmark to complete."
}


####################################################
# 	"thread-safe" xoSoap Invoker (ServiceRegistry)
####################################################

::xotcl::THREAD create xosoap::tsfInvoker {

::xotcl::Object Invoker

Invoker ad_proc invoke { soapxmlMessage serviceName } {} {

    set output ""
    set errorObj ""
    
if { ![catch {

    ::xosoap::marshaller::MessageContext msgContext
   

    ::xosoap::marshaller::Marshaller marshaller
    set requestMsgCtx [marshaller demarshal msgContext $soapxmlMessage]
    
    ::xosoap::visitor::SoapDemarshallerVisitor dv

    dv releaseOn [[$requestMsgCtx requestMessage] soapEnvelope]

    set method [dv serviceMethod]

    # get proxy from service registry
    set proxy [lindex [[self]::ServiceRegistry getProxy $serviceName] 1]
    
    # dispatch call on proxy
    
     set tmpArgs ""
     
     foreach keyvalue [dv serviceArgs] {	 
		
		#my log "i: [lindex $keyvalue 0], j: [lindex $keyvalue 1]"
		append tmpArgs " " "{[lindex $keyvalue 1]}"
		     
	  
	  }
    my log "List of arguments passed: $tmpArgs"
    set result [eval $proxy $method $tmpArgs]
    
    # pass results to marshaller
    
    set responseMsgCtx [marshaller marshal $requestMsgCtx $result]

    set output [[$responseMsgCtx responseMessage] asXML]
    
} errorObj]  } {

	return "ns_return 200 text/xml {$output}"

} else {
    
   set faultObj ""
	# is exception object?
    if {[my isobject $errorObj]} { set faultObj [::xosoap::marshaller::SoapFault faultObj -exception $errorObj]} else {
set defaultException [::xosoap::Exception defaultException -errorCode "-1" -errorMessage "$errorObj" -faultCode "Server.Unknown"]	
	set faultObj [::xosoap::marshaller::SoapFault faultObj -exception $defaultException] 
	
    }
    
    return "ns_return 500 text/xml {[$faultObj asXML]}"
}

    
}

Invoker ad_proc -public true register {className} {} {


	# Lifecycle Manager Registry
	
		# compute object id: 	[1-8]	hexed md5 hash of type string
		#						[9-16]	hexed millisec integer of current time
		#						[17-24]	hexed integer of ip address of current host
		
		set typeHex [::md5::md5 $className]
		set timeHex [format %x [clock seconds]]
		
		set ipHex ""
		foreach ipPart [split [ns_info address] "."] {
		
			append ipHex "" [format %x $ipPart]
		
		}
		#set ipHex	[format %x [join [split [ns_info address] "."] ""]]
		
		set objIdentifier "$typeHex$timeHex$ipHex"
		
		# create Lifecycle Manager and initiate lifecycle strategy
		
		set managerName [my autoname lcm]
		::xosoap::lifecycle::LifecycleManager $managerName
		
		my debug [$className lifecycle]
		
		switch [$className lifecycle] {		
			0 { eval [$managerName strategy] class ::xosoap::lifecycle::PerRequestStrategy }
			1 { eval [$managerName strategy] class ::xosoap::lifecycle::StaticInstanceStrategy }		
		}
		
		my debug [[$managerName strategy] info class]
		 		
		# call strategy specific registration
		
		set objProxy [::$managerName register $objIdentifier $className]
		
		# register with LCM
		
		[self]::LCMRegistry stock $objIdentifier ::$managerName
		
		
	
	# Service Registry
	
		set classAsString [set className]
		# extract name of service/ endpoint from fully-qualified object name
	    set trimmedClassAsString [string trimleft $classAsString {:}]
	    set objNameAsList [lsearch -all -inline -not [split $trimmedClassAsString {::}] ""]
	    set serviceName [lindex $objNameAsList [expr {[llength $objNameAsList] - 1}] ]
	
		# deposit with service registry
		
		[self]::ServiceRegistry add $serviceName $objProxy
		#my log "Registered Service Class $class in NS $namespace publishing service methods $services as endpoint $serviceName"
		
}

Invoker ad_proc -public true unregister {className} {} {}


####################################################
# xoSoap Invoker::ServiceRegistry
####################################################

 
::xotcl::Object Invoker::ServiceRegistry -set serviceRegistry(lastid) 0 -ad_doc {}

Invoker::ServiceRegistry ad_proc add {serviceName objProxy} {} {

	my instvar {serviceRegistry sr}
    
    set id [incr sr(lastid)]
    set sr($id,service_name) $serviceName
    set sr($id,proxy) $objProxy

   }

Invoker::ServiceRegistry ad_proc getProxy {serviceName} {} {

    my instvar {serviceRegistry sr}
    #my log "i am here"
    set result {}
    set id {}
    foreach i [array names sr  *,service_name] {
	#my log "+++ $i => $sr($i) <eq> $serviceName"
	if {[expr {$sr($i) eq $serviceName}]} {
	    set id [lindex [split $i ,] 0]
	    set result [my getField $id proxy]
	    #my log "++++ $id => $result"
	    break
	}
    }
    
    #my log "+++ found $id => $result"
    return [list $id $result];
	
}

Invoker::ServiceRegistry ad_proc -public true getField {rowId fieldName} {} {

    my instvar {serviceRegistry sr}

    if {[array names sr $rowId,$fieldName]=="$rowId,$fieldName"} {
        return $sr($rowId,$fieldName)
    } else {return ""}

}

Invoker::ServiceRegistry ad_proc -public true getIds {} {} {

	my instvar {serviceRegistry sr}
    
    set ret_list [list]
    
    puts [array names sr  *,service_name]

    return $ret_list

}
####################################################
# embedding a lifecycle manager registry
####################################################


::xosoap::lifecycle::LifecycleManagerRegistry Invoker::LCMRegistry

} -persistent 1

####################################################
# Service Meta-Class
####################################################

::xotcl::Class xosoap::Service -superclass ::xotcl::Class -parameter {{lifecycle 0} hoard} -ad_doc {

	<p>This meta-class serves as skeleton for declaring services, its main purpose is a threefold:</p>
	<p>
	<ul>
		<li>It provides for the registration of defined service classes after OACS finishes its init phase.</li>
		<li>It allows for specify a lifecycle strategy (see <a href='/xotcl/show-object?object=xosoap::lifecycle::AbstractLifecycleStrategy'>xosoap::lifecycle::AbstractLifecycleStrategy</a>) for the remote objects to be created thereof by setting its lifecycle parameter. A parameter value of "0" (default) refers to a per-request lifecycle (see <a href='/xotcl/show-object?object=xosoap::lifecycle::PerRequestStrategy'>xosoap::lifecycle::PerRequestStrategy</a>), a value of "1" to static service instances (see <a href='/xotcl/show-object?object=xosoap::lifecycle::StaticInstanceStrategy'>xosoap::lifecycle::StaticInstanceStrategy</a>).</li>
		<li>It is possible to disclose certain methods of a service (instance) by passing a tcl list of names of "hoarded" methods to the hoard parameter upon creation of the service class. These will not be exposed as service methods.</li>
	</ul> </p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October 12, 2005 
	
	
	@see <a href='/xotcl/show-object?object=xosoap::lifecycle::PerRequestStrategy'>xosoap::lifecycle::PerRequestStrategy</a>
	@see <a href='/xotcl/show-object?object=xosoap::lifecycle::StaticInstanceStrategy'>xosoap::lifecycle::StaticInstanceStrategy</a>
	
	}

::xosoap::Service ad_instproc init {} {

	<p>The meta-class' constructor takes care of the post-initialisation registration of services. "Post-initialisation" refers to the fact that the actual registration is performed after, and only after the entire OACS init phase is finished. Registration of services as such is handled by the Invoker within the Invoker thread (see ...). Due to the problematic design and implementation of OACS's initialisation and bluepriniting (details are discussed in a recent <a href="http://openacs.org/forums/message-view?message_id=324185">thread</a> in the OACS forum), it is necessary to postpone service registration, i.e. invoking the Invokers registration facility, at the latest point in time possible. This is achieved by depositing the register call on the Invoker with the predefined nsv array "ad_after_server_initialization". The calls stored in this nsv array are finally processed in "zz-postload.tcl"</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October 12, 2005 
	
	@see ad_after_server_initialization
} {
        
    eval ad_after_server_initialization [self] { ::xosoap::tsfInvoker do Invoker register [self] }
    
}

####################################################
# Exception handling
####################################################

::xotcl::Class xosoap::Exception -parameter {errorCode errorMessage {stackTrace ""} {faultCode "Server"} {exceptionNS {xosoap http://nm.wu-wien.ac.at/xosoap\#}}} -ad_doc {

	This class provides object encapsulation for a simple exception handling in xoSoap. Exceptions are caught within the Invokers
	<a href='/api-doc/proc-view?proc=Invoker::invoke'>invoke</a> procedure, finally re-packaged as Soap Faults by <a href='/xotcl/show-object?object=xosoap::marshaller::SoapFault'>xosoap::marshaller::SoapFault</a> and handed back to the calling client.
		
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August 25, 2005 	
	
	
}
::xosoap::Exception ad_instproc asXML {} {

	This method casts the Exceptions state into a application-specific, XML-flavoured reporting format.

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August 25, 2005 	
	
	


} {
    my instvar errorCode errorMessage stackTrace exceptionNS
    set output ""
    append output "<[lindex exceptionNS 0]:Exception xmlns:[lindex exceptionNS 0]=\"[lindex exceptionNS 0]\">"
    append output "<errorCode>$errorCode</errorCode>"
    append output "<errorMessage>$errorMessage</errorMessage>"
    append output "<stackTrace>$stackTrace</stackTrace>"
    append output "</[lindex exceptionNS 0]:Exception>"
    return $output
    
}
