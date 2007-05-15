####################################################
# Soap Protocol-Plugin + facilities 
####################################################

ad_library {
  
  @author stefan.sobernig@wu-wien.ac.at
  @creation-date August 18, 2005
  @cvs-id $Id$

  
}

namespace eval ::xosoap {

  namespace import -force ::xoexception::try
  namespace import -force ::xosoap::exceptions::*
  namespace import -force ::xorb::*
  namespace import -force ::xorb::transport::*
  namespace import -force ::xorb::protocols::*
  namespace import -force ::xorb::context::*
  namespace import -force ::xorb::datatypes::*

  # # # # # # # # # # # # # #
  # # # # # # # # # # # # # #
  # # 1) basic http listener
  # # # # # # # # # # # # # #
  # # # # # # # # # # # # # #
  
  ListenerClass SoapHttpListener -superclass TransportListener \
      -protocol "Http" \
      -plugin "::xosoap::Soap"
  SoapHttpListener forward preauth %self initialise 
  SoapHttpListener proc initialise {} {
    # create listener instance
    my contextClass ::xosoap::SoapInvocationContext 
    next;#ListenerClass->initialise + require ::xo::cc
    # populate with remoting specific tags
    # populate with transport + protocol tag
    ::xo::cc actual_query [ns_conn query]
    ::xo::cc transport [my protocol]
    ::xo::cc protocol [my plugin]
    ::xo::cc method [ns_conn method]
    ::xo::cc marshalledRequest [ns_conn content]
    # we require the SOAPAction header field to
    # be present in the http post request,
    # however its value is of no significance
    # (for endpoint resolution etc.)
    set headerSet [ns_conn header]
    set idx [ns_set find $headerSet SOAPAction]
    if {[::xo::cc method] eq "POST" && $idx != -1} {
      # keep in context object for later use!
      ::xo::cc action [ns_set value $headerSet $idx]
      return filter_ok;
    } elseif {[::xo::cc method] eq "GET"} {
      my log context=[::xo::cc serialize]
      return filter_ok;
    } else {
      return filter_return;
    }
  }
  SoapHttpListener proc redirect {} {
    # TODO: move to ListenerClass->redirect?
    [my plugin] plug -listener [self]::listener
    next;#ListenerClass->redirect
    my terminate; # unplug
  }
  SoapHttpListener instproc processRequest {{requestObj {}}} {
    # actual processing
    set service_prefix [parameter::get -parameter "service_url" -default \
			    "services"]
    set package_key [apm_package_key_from_id [::xo::cc package_id]]
    set url [string trim [::xo::cc url] /]
    set urlv [split $url /]
    set urlc [llength $urlv]
    catch {
      
      # / / / / / / / / / / / / / /
      # verifying url
      if {$urlc ne "3" || [lindex $urlv 1] ne $service_prefix} {
	error [MalformedEndpointException new]
      }
      ::xo::cc virtualObject [lindex $urlv 2]
      my log INSIDE=[::xo::cc serialize]
      switch -exact [::xo::cc method] {
	"GET" {
	  # meant to be request for wsdl; verify first
	  if {[::xo::cc actual_query] eq "wsdl"} {
	    # / / / / / / / / / / / / /
	    # TODO: introduce general dispatch mechanism
	    # later on OR introduce admin service
	    # which deals with these tasks (wsdl etc.)
	    ::xorb::Skeleton mixin add ::xosoap::Wsdl1.1
	    set implObj [::xorb::Skeleton getImplementation \
			     -name [::xo::cc virtualObject]]
	    set wsdl [::xorb::Skeleton getContract \
			  -name [$implObj implements]]
	    ::xorb::Skeleton mixin delete ::xosoap::Wsdl1.1
	    #eval [my getWSDL -servicePointer  [::xo::cc virtualObject]]
	  } else {
	    error [HttpRequestException new {
	      'wsdl' only is allowed / required as parameter in GET requests
	    }]
	  }
	} 
	"POST" {
	  # an actual http request with soap payload
	  if {[::xo::cc marshalledRequest] ne {}} {
	    set super [[my info class] info superclass]
	    my log "---msg=[::xo::cc marshalledRequest],next=[self next],super=$super,m=[my info methods]"
	    next [::xo::cc marshalledRequest];# TransportListener->processRequest
	  } else {
	    error [HttpRequestException new {
	      Payload is missing in POST request
	    }]
	  }
	}
      }
    } e

    if {[::xoexception::Throwable isThrowable $e]} {
      $e write
      #my terminate;# unplug protocol + abort script
    } else {
      global errorInfo
      [UnknownException new $errorInfo] write
      #my terminate;# unplug protocol + abort script
    }
    my log "---PASSING---"
  }
  SoapHttpListener instproc dispatchResponse {payload} { 
    eval ns_return 200 text/xml $payload
  }

  # # # # # # # # # # # # # #
  # # # # # # # # # # # # # #
  # # 2) Protocol-Plugin

  PluginClass Soap -ad_doc {
    
    A Protocol-Plugin allows for either ...
    -1- mixing-in into the initial / final actions of the 
    RequestHandler (handleRequest/ handleResponse)
    -2- adding protocol-specific interceptors to the chain
    of interceptors for the protocol-specific call.
 
  } -superclass RemotingPlugin
  Soap instproc handleRequest {requestObj} {
    my log "---requestObj-1:$requestObj"
    catch {
      next;#::xorb::RequestHandler->handleRequest
    } e
    
    if {[::xoexception::Throwable isThrowable e]} {
      # / / / / / / / / / / / / / / /
      # re-cast xorb exceptions into
      # proper SOAP faults
      error [::xosoap::exceptions::Server::InvocationException new $e]
    } else {
      global errorInfo
      my log "---e=$e, $errorInfo"
      error [::xosoap::exceptions::Server::UnknownInvocationException new \
		 $e]
    }
  }
  Soap instproc handleResponse {requestObj returnValue} {
     # / / / / / / / / / / / / / / / / / / / / /
    # 1) SoapResponseVisitor
    set visitor [::xosoap::visitor::InvocationDataVisitor new -volatile \
		     -batch $returnValue] 

    # / / / / / / / / / / / / / / / / / / / / 
    # TODO: default to [::xo::cc unmarshalledRequest] or
    # most current state of request object as skeleton for the response
    # object?
    #set responseObj [::xo::cc unmarshalledRequest];
    # $requestObj?
    set responseObj $requestObj
    # / / / / / / / / / / / / / / / / / / / / /
    # 2) Transform request into response object
    $visitor releaseOn $responseObj

    # / / / / / / / / / / / / / / / / / / / / /
    # 3) preserve original response object before passing it through
    # the response flow of interceptors
    set unmarshalled [::xotcl::Object autoname soap]
    $responseObj copy $unmarshalled
    ::xo::cc unmarshalledResponse $unmarshalled
    
    # ::xorb::RequestHandler->handleResponse
    
    set r [next $responseObj];
    [my listener] dispatchResponse $r
  }

  # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # #
  # # 3) Protocol interceptors


  ####################################################
  # 	DeMarshallingInterceptor	
  ####################################################

  Interceptor DeMarshallingInterceptor

  DeMarshallingInterceptor instproc handleRequest {requestObj} {
    
    try {
      # / / / / / / / / / / / / / / / / / / / / 
      # 1) modify args > parse into soap object tree
      
      set doc [dom parse $requestObj]
      set root [$doc documentElement]
      
      set requestObj [::xosoap::marshaller::SoapEnvelope new]
      $requestObj parse $root
      
      # / / / / / / / / / / / / / / / / / / / / 
      # 2) populate invocation context
      ::xo::cc version [my getSoapVersion $requestObj]
      set unmarshalled [::xotcl::Object autoname soap]
      $requestObj copy $unmarshalled
      ::xo::cc unmarshalledRequest $unmarshalled
      
      my log "endpoint=[::xo::cc virtualObject],version=[::xo::cc version]"
    } catch {Exception e} {
      # rethrow
      error $e
    } catch {error e} {
      error [::xosoap::exceptions::Server::DemarshallingException new $e]
    }
    
    # / / / / / / / / / / / / / / / / / / / / /
    # 3) pass on unmarshalled request
    next $requestObj
  }

  DeMarshallingInterceptor instproc handleResponse {responseObj} {
    
    set visitor [::xosoap::visitor::SoapMarshallerVisitor new -volatile]
    my log RESPONSEOBJ=$responseObj,[$responseObj info class]
    $visitor releaseOn $responseObj
    my log "XML=[[$visitor xmlDoc] asXML]"
    next [list [[$visitor xmlDoc] asXML]]
    
  }


  DeMarshallingInterceptor ad_instproc -private getSoapVersion {soapEnvelope} {
    
    <p>Helps identify the SOAP standard's version the incoming and parse 
    SOAP request adheres to. Therefore, it verifies both the encoding and 
    envelope namespaces attached to the SOAP request. If there is a version 
    mismatch between the two, a general fallback to the envelope's version 
    is provided. Reference values for the version namespaces are taken from 
    the <a href='http://www.w3.org/TR/2000/NOTE-SOAP-20000508/\#_Toc478383495'\
	>SOAP 1.1</a> and <a href='http://www.w3.org/TR/2003/REC-soap12-part1-\
	20030624/\#soapenv'>SOAP 1.2</a> specs.</p>
    
    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 19 2005
    
    @param soapEnvelope The SOAP tree of objects which also stores encoding 
    and envelope version information, i.e. the namespace URIs extracted from 
    the SOAP request.
    @return A Tcl string representing the SOAP version on hand. Return value 
    is either "1.1" or "1.2".
    
    @see <a href='/xotcl/proc-view?proc=::xosoap::marhsaller::Marshaller+\
	instproc+demarshal'>::xosoap::marhsaller::Marshaller demarshal</a>
    
  } {
    set soapEncVersion {}
    switch [$soapEnvelope encodingStyle] {
      "http://schemas.xmlsoap.org/soap/encoding/" {
	set soapEncVersion 1.1 
      }
      "http://www.w3.org/2003/05/soap-encoding" {
	set soapEncVersion 1.2
      }
      "http://www.w3.org/2003/05/soap-envelope/encoding/none" {
	set soapEncVersion 1.2
      }
    }
    set soapEnvVersion {}
    switch [$soapEnvelope nsEnvelopeVersion] {
      "http://schemas.xmlsoap.org/soap/envelope/" {
	set soapEnvVersion 1.1
      }
      "http://www.w3.org/2003/05/soap-envelope" {
	set soapEnvVersion 1.2
      }
    }
    if {[expr { $soapEncVersion eq $soapEnvVersion }]} {
      return $soapEncVersion
    } else {
      # fallback to version of envelope namespace
      my debug "Version mismatch between envelope/ encoding-style namespaces."
      return $soapEnvVersion
    }
  }

  # # # # # # # # # # # # # #
  # # # # # # # # # # # # # #
  # # register interceptors
  # # with ::xorb::Base
  # # configuration

  Soap registerInterceptors {
    ::xosoap::DeMarshallingInterceptor
    ::xosoap::LoggingInterceptor
  }

  # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # #
  # # 4) Protocol-specific
  # # context

  ContextClass SoapInvocationContext -parameter {
    {action {}}
    {version "1.1"}
  } -superclass RemotingInvocationContext

  # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # #
  # # 5) Invocation Data and Dispatch
  # # Styles
  
  ::xotcl::Class RpcLiteral -contains {
    Class SoapMarshallerVisitor \
	-instproc SoapBodyResponse {obj} {
	  my instvar xmlDoc parentNode
	  $obj instvar __node__
	  
	  # / / / / / / / / / / / / / / / / / / / / / / / /
	  # SOAP 1.1 spec only stipulates / recommends that 
	  # the first child element of SoapBody is suffixed
	  # with *Response. There is no naming convention,
	  # apart from framework-specific ones, on elements
	  # containing the return value(s).
	  # Currently, we provide for a suffix: *Return
	  # TODO: adapt to multiple / complex return values 
	  # (types).
	  
	  # / / / / / / / / / / / / / / / /
	  # introduce anythings and appropriate
	  # delegation to the concrete marshaller
	  # provided by the actual any implementation
	  # TODO: support for multiple anys
	  
	  if {[$obj responseValue] eq {}} {
	    set any [::xosoap::xsd::XsAnything new -isVoid true]
	  } else {
	    set any [$obj responseValue]
	  }
	  set name [string map {Response Return} [$obj elementName]]
	  set anyNode [$__node__ appendChild \
			   [$xmlDoc createElement $name]]
	  $any marshal $xmlDoc $anyNode $obj
	}
    Class InboundRequest \
	-instproc SoapBodyRequest {obj} {
	my instvar serviceMethod serviceArgs
	my log CALL=[$obj elementName]
	::xo::cc virtualCall [$obj elementName]
	#set tmpArgs ""
	#foreach keyvalue [$obj set methodArgs]  {	 
	#  append tmpArgs " " "{[lindex $keyvalue 1]}"     
	#}     
	::xo::cc virtualArgs [$obj set methodArgs]
      }
    Class OutboundResponse \
      -instproc SoapBodyRequest {obj} {
	$obj class ::xosoap::marshaller::SoapBodyResponse
	$obj elementName [$obj set targetMethod]Response
	$obj set style [[self class] info parent]
	$obj responseValue [my batch]
      }
    Class OutboundRequest \
	-instproc SoapBodyRequest {obj} {
	  my instvar invocationContext
	  $obj elementName [$invocationContext virtualCall]
	  $obj set methodArgs [$invocationContext virtualArgs]
	  if {[$invocationContext exists callNamespace]} {
	    # / / / / / / / / / / / / / / /
	    # TODO: default namespace support!!!!!
	    $obj registerNS [list "m" [$invocationContext callNamespace]]
	  } 
	}
    Class InboundResponse \
	-instproc SoapBodyResponse {obj} {
	  my instvar invocationContext
	  $invocationContext unmarshalledResponse [$obj responseValue]
	}
  }
  
  ::xotcl::Class DocumentLiteral -contains {
    Class SoapMarshallerVisitor \
	-instproc SoapBodyResponse {obj} {
	  my instvar xmlDoc parentNode
	  $obj instvar __node__
	  if {[$obj responseValue] eq {}} {
	    set any [::xosoap::xsd::XsAnything new -isVoid true]
	  } else {
	    set any [$obj responseValue]
	  }
	  $any marshal $xmlDoc $__node__ $obj
	}
    Class InboundRequest \
	-instproc SoapBodyRequest {obj} {
	  my instvar serviceMethod serviceArgs
	  my log CALL=[$obj elementName]
	  # / / / / / / / / / / / / / / / / /
	  # resolve call from SOAPAction
	  # header (as necessary in D/L style)
	  set actionUrl [::xo::cc action]
	  if {$actionUrl eq {}} {
	    error "Dispatch impossible."
	  }
	  # / / / / / / / / / / / / / / / / /
	  # provide for Chain of Resp. for
	  # resolving the call info:
	  # 1) action header
	  # 2) element namespace?
	  # header (as necessary in D/L style)
	  set url [string trim $actionUrl /]
	  set urlv [split $url /]
	  ::xo::cc virtualCall [lindex $urlv end]
	  #set tmpArgs ""
	  #foreach keyvalue [$obj set methodArgs]  {	 
	  #  append tmpArgs " " "{[lindex $keyvalue 1]}"     
	  #}     
	  # / / / / / / / / / / /
	  # repack Request element into
	  # Anything! 
	  # TODO: what if multiple
	  # request elements?
	  # TODO: Use of 'parameters' as default when only
	  # one element! Seems to be a hint/ hack from .NET
	  # Remoting that therefore tries to expose a true
	  # RPC service as a Document based one!
	  # TODO: How to handle Document/Literal if multiple
	  # arguments are passed, not indicating the argument
	  # flag: In XOTcl terms, how to handle nonposArgs 
	  # in this matter:
	  # - translate into posArgs (as hack for legacy 
	  # service contracts)?
	  set any [::xorb::datatypes::Anything new -name "parameters"]
	  foreach a [$obj set methodArgs] {
	    $any add -parse $a
	  }
	  ::xo::cc virtualArgs $any
	}
	  
    Class OutboundResponse \
	-instproc SoapBodyRequest {obj} {
	  $obj class ::xosoap::marshaller::SoapBodyResponse
	  set any [my batch] 
	  if {[$any istype ::xosoap::xsd::XsCompound]} {
	    set n [namespace tail [$any set template]]
	    $obj elementName $n
	    $obj responseValue [my batch]
	    $obj set style [[self class] info parent]
	    $obj unregisterNS "m"
	  }
	  #my log RESPONSEANY=[$any serialize]
	  #$obj elementName []
	  #$obj elementName [$obj set targetMethod]Response
	}
    Class OutboundRequest
    Class InboundResponse
  }
  

  namespace export SoapHttpListener Soap DeMarshallingInterceptor \
      LoggingInterceptor SoapInvocationContext RpcLiteral DocumentLiteral
}


