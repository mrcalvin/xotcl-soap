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
  namespace import -force ::xorb::aux::*
 


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
    next;#ListenerClass->initialise 
    return filter_ok;
  }
#   SoapHttpListener proc redirect {} {
#     # TODO: move to ListenerClass->redirect?
#     #[my plugin] plug -listener [self]::listener
#     next;#ListenerClass->redirect
#     #my terminate; # unplug
#   }
  SoapHttpListener instproc processRequest {} {

    # / / / / / / / / / / / / / / / / / / / / / / / / / 
    # Starting with 0.4, post-filter (or rather post-
    # query-processor) processing involves the following
    # stages
    # 1-) require a package manager instance + 
    # connextion context (::xo::cc) and set 
    # 2-) populate the previously acquired invocation
    # context
    # xorb specific extensions
    # 3-) forward to package dispatcher
    if {[catch {      
      # -- 1-)
      # We provide for a slightly different
      # initialisation semantic depending
      # on where the requests debarks
      set service_prefix [parameter::get -parameter "service_segment" \
			      -default "services"]
      #set package_key [apm_package_key_from_id [::xo::cc package_id]]
      set url [string trim [ns_conn url] /]
      set urlv [split $url /]
      set urlc [llength $urlv]
      set delimiter [lsearch -exact $urlv $service_prefix]

      # / / / / / / / / / / / / / /
      # verifying locator
      
      if {$delimiter == -1} {
	error [MalformedEndpointException new [subst {
	  Service prefix '$service_prefix' not given in resource locator 
	  '$url'.
	}]]
      }
      
      set params [list -s:optional "badge"]
      if {[ns_conn method] eq "POST"} {
	set params [list -s:optional "invocation"]
      }
      set oidv [lrange $urlv [expr {$delimiter + 1}] end]
      my set fragment [join $oidv /]
      
      ::xosoap::Package initialize \
	  -user_id [acs_magic_object "unregistered_visitor"] \
	  -parameter [list $params]
      
      ::$package_id configure \
	  -protocol [[my info class] plugin] \
	  -listener [self]
      ::xo::cc httpMethod [ns_conn method]
      
      # -- 3-)
      

      my debug params=$params,solicit=$s
      ::$package_id solicit $s
      # - - - - - - - - - - - - - - - - - - - - - - - -
    } e]} {
      if {[::xoexception::Throwable isThrowable $e]} {
	$e write [::$package_id self]
      } else {
	[UnknownException new $e] write [::$package_id self]
      }
    }
  }
  SoapHttpListener instproc dispatchResponse {
    statusCode
    contentType
    payload
  } { 
    ns_return $statusCode $contentType $payload
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
 
  } -superclass RemotingPlugin \
      -contextClass "::xosoap::SoapInvocationContext"

  Soap instproc handleRequest {context} {

    if {[catch {
      ::xorb::Invoker instmixin add [self class]::Invoker
      next;#::xorb::RequestHandler->handleRequest
      ::xorb::Invoker instmixin delete [self class]::Invoker
    } e]} {
      
      if {[::xoexception::Throwable isThrowable e]} {
	# / / / / / / / / / / / / / / /
	# re-cast xorb exceptions into
	# proper SOAP faults
	error [::xosoap::exceptions::Server::InvocationException new $e]
      } else {
	#global errorInfo
	#my debug "---e=$e, $errorInfo"
	error [::xosoap::exceptions::Server::UnknownInvocationException new \
		   $e]
      }
    }
  }
  Soap instproc handleResponse {context returnValue} {
     # / / / / / / / / / / / / / / / / / / / / /
    # 1) SoapResponseVisitor
    set visitor [::xosoap::visitor::InvocationDataVisitor new \
		     -volatile \
		     -batch $returnValue \
		     -invocationContext $context] 

    # / / / / / / / / / / / / / / / /
    # Starting with 0.4, we return a 
    # 'virgin' envelope object to
    # be further processed. up to this
    # moment we re-used the demarshalled/
    # mangled request object, however,
    # this turned out to be hairy in 
    # terms of visitor traversals through
    # OrderedComposite structures. btw.,
    # this also renders the interceptors
    # somehow useless, as most of them
    # would use visitors to access and
    # mangle the message objects.

    set responseObj [::xosoap::marshaller::SoapEnvelope new \
			 -response true]
    my debug "NEWRESPONSE=[$responseObj serialize]"
    # / / / / / / / / / / / / / / / / / / / / /
    # 2) Transform request into response object
    $visitor releaseOn $responseObj

    # / / / / / / / / / / / / / / / / / / / / /
    # 3) preserve original response object before passing it through
    # the response flow of interceptors
    $context unmarshalledResponse $responseObj
    
    set r [next $context];
    [my listener] dispatchResponse 200 text/xml $r
  }

  Class Soap::Invoker -instproc init args {
    my instvar context
    # / / / / / / / / / / / / / / / / / / /
    # Call InvocationDataVisitor to
    # extract the invocation data from
    # the SOAP message object into the 
    # context object (::xo::cc)
    set visitor [::xosoap::visitor::InvocationDataVisitor new \
		     -volatile \
		     -invocationContext $context]
    $visitor releaseOn [$context unmarshalledRequest]
    next;# Invoker->init
  }

  
  # / / / / / / / / / / / / / / /
  # The invoker is assigned the
  # role of an the main addressing
  # prinicipal: As the invoker is
  # responsible to dispatch the actual
  # call to the skeleton object (or
  # remote object as called in literature)
  # it is the place to resolve a
  # shared object id (object reference)
  # to the corresponding internal
  # name of the service implementation.
  # This resolved name is then used
  # to generate the actual skeleton.
  # Currently, we only need a single
  # resolution strategy, from URL components
  # to the internal namespace notation.

  Soap::Invoker instproc resolve {objectId} {
    # / / / / / / / / / / / / /
    # we assume the following identifier
    # input: </>internal/pointer/to/service</>
    # there is one major exception or special
    # constraint. whenever there is a fragment
    # acs as the first part of the path fragment
    # it resolves to the unqualified (not resolvable)
    # to a concrete tcl namespace / fully qualified
    # tcl name. this allows, for instance, to integrate
    # the old service contracts and implementations.
    set oidv [split $objectId /]
    set oidc [llength $oidv]
    if {[lindex $oidv 0] ne "acs"} {
      set objectId ::[join $oidv ::]
    } else {
      if {$oidc > 2} {
	error {
	  Object identifiers that resolve to the reserved and 
	  virtual namespace 'acs' can only contain one suceeding 
	  path fragment.}
      }
      set objectId [lindex $oidv 1]
    }
    # translated form: ::internal::pointer::to::service
    return $objectId
  }

  # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # #
  # # 3) Protocol interceptors


  ####################################################
  # 	DeMarshallingInterceptor	
  ####################################################

  Interceptor DeMarshallingInterceptor

  DeMarshallingInterceptor instproc handleRequest {context} {
    
    try {
      # / / / / / / / / / / / / / / / / / / / / 
      # 1) modify args > parse into soap object tree
      set requestObj [$context marshalledRequest]
      set doc [dom parse $requestObj]
      set root [$doc documentElement]
      
      set requestObj [::xosoap::marshaller::SoapEnvelope new -header]
      $requestObj parse $root
      
      # / / / / / / / / / / / / / / / / / / / / 
      # 2) populate invocation context
      $context version [my getSoapVersion $requestObj]
      $context unmarshalledRequest $requestObj

      # / / / / / / / / / / / / / / / / / / / /
      # 2.1)
      # get context data
      set contextVisitor [::xosoap::visitor::ContextDataVisitor new \
			      -volatile \
			      -context $context]
      $requestObj accept $contextVisitor
      my debug context=[$context array get data]
      my debug "endpoint=[$context virtualObject],version=[$context version]"
    } catch {Exception e} {
      # rethrow
      error $e
    } catch {error e} {
      #global errorInfo
      error [::xosoap::exceptions::Server::DemarshallingException new $e]
    }
    
    # / / / / / / / / / / / / / / / / / / / / /
    # 3) pass on unmarshalled request
    next $context
  }

  DeMarshallingInterceptor instproc handleResponse {context} {
    set responseObj [$context unmarshalledResponse]
    set visitor [::xosoap::visitor::SoapMarshallerVisitor new -volatile]
    my debug RESPONSEOBJ=$responseObj,[$responseObj info class]
    $visitor releaseOn $responseObj
    my debug "XML=[[$visitor xmlDoc] asXML]"
    next [[$visitor xmlDoc] asXML]
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

  ::xotcl::Class SoapInvocationContext -parameter {
    action
    {version "1.1"}
  } -superclass RemotingInvocationContext

  # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # #
  # # 5) Invocation Data and Dispatch
  # # Styles

  AggregationClass RpcEncoded -contains {
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
	    set any [::xosoap::xsd::XsAnything new -isVoid__ true]
	  } else {
	    set any [$obj responseValue]
	  }
	  set name [string map {Response Return} [$obj elementName]]
	  set anyNode [$__node__ appendChild \
			   [$xmlDoc createElement $name]]
	  
	  set style [[self class] info parent]

	  # / / / / / / / / / / / / / / /
	  # Introduce styles for marshaling
	  # of messages!
	  set class [$any info class]
	  foreach h [concat $class [$class info heritage]] {
	    set hstripped [namespace tail $h]
	    set mixins {}
	    if {[my isclass ${style}::${hstripped}]} {
	      append mixins ${style}::${hstripped}
	      $any mixin add ${style}::${hstripped}
	    }
	  }
	  $any marshal $xmlDoc $anyNode $obj
	  foreach m $mixins {
	    $any mixin delete $m
	  }
	}  -instproc SoapBodyRequest {obj} {
	  my instvar xmlDoc parentNode
	  $obj instvar methodArgs __node__
	  
	  # / / / / / / / / / / / / / / / / /
	  # Introducing anythings!
	  foreach any $methodArgs {
	    set anyNode [$__node__ appendChild \
			     [$xmlDoc createElement [$any name__]]]
	    # / / / / / / / / / / / / / / /
	    # Introduce styles for marshaling
	    # of messages!
	    set style [[self class] info parent]
	    set class [$any info class]
	    my debug MAR=cl=$class,style=$style
	    set mixins {}
	    foreach h [concat $class [$class info heritage]] {
	      set hstripped [namespace tail $h]
	      if {[my isclass ${style}::${hstripped}]} {
		append mixins ${style}::${hstripped}
		$any mixin add ${style}::${hstripped}
	      }
	    }
	    my debug mixins=$mixins
	    $any marshal $xmlDoc $anyNode $obj
	    foreach m $mixins {
	      $any mixin delete $m
	    }
	  }
	}
    Class InboundRequest \
	-instproc SoapBodyRequest {obj} {
	  my instvar serviceMethod serviceArgs \
	      invocactionContext
	  my debug CALL=[$obj elementName]
	  $invocationContext virtualCall [$obj elementName]
	  #set tmpArgs ""
	  #foreach keyvalue [$obj set methodArgs]  {	 
	  #  append tmpArgs " " "{[lindex $keyvalue 1]}"     
	  #}     
	  $invocationContext virtualArgs [$obj set methodArgs]
	}
    Class OutboundResponse \
	-instproc SoapBodyResponse {obj} {
	  # / / / / / / / / / / / /
	  # Starting with 0.4,
	  # we assume a pre-existing
	  # SoapBodyResponse element.
	  my instvar invocationContext
	  #$obj class ::xosoap::marshaller::SoapBodyResponse
	  $obj elementName [$invocationContext virtualCall]Response
	  $obj set style [[self class] info parent]
	  $obj responseValue [my batch]
	} \
	-instproc SoapEnvelope {obj} {
	  $obj registerNS [list "xsd" "http://www.w3.org/2001/XMLSchema"]
	  $obj registerNS [list "xsi" \
			       "http://www.w3.org/2001/XMLSchema-instance"]
	  # / / / / / / / / / / / / / /
	  # only in encoded style, 
	  # add an encodingStyle attribute
	  # for the per-envelope level,
	  # and the required namespace
	  # declaration.
	  # This is somehow related to
	  # WS-I BP 1.1 requirement 1005
	  $obj registerNS \
	      [list "SOAP-ENC" "http://schemas.xmlsoap.org/soap/encoding/"]
	  $obj registerEnc "http://schemas.xmlsoap.org/soap/encoding/"
	}
    Class OutboundRequest \
	-instproc SoapBodyRequest {obj} {
	  my instvar invocationContext
	  $obj elementName [$invocationContext virtualCall]
	  $obj set methodArgs [$invocationContext virtualArgs]
	  $obj set style [[self class] info parent]
	  set ns [$invocationContext getCallNamespace]
	  if {$ns ne {}} {
	    array set tmp $ns
	    # / / / / / / / / / / / / / / /
	    # TODO: default namespace support!!!!!
	    $obj elementNamespace $tmp(prefix)
	    $obj registerNS [list $tmp(prefix) $tmp(uri)]
	    if {$tmp(prefix) eq {}} {
	      # -- is default namespace
	      $obj unregisterNS "m"
	    } 
	  } 
	}\
	-instproc SoapEnvelope {obj} {
	  $obj registerNS [list "xsd" "http://www.w3.org/2001/XMLSchema"]
	  $obj registerNS [list "xsi" \
			       "http://www.w3.org/2001/XMLSchema-instance"]
	  # / / / / / / / / / / / / / /
	  # only in encoded style, 
	  # add an encodingStyle attribute
	  # for the per-envelope level,
	  # and the required namespace
	  # declaration.
	  # This is somehow related to
	  # WS-I BP 1.1 requirement 1005
	  $obj registerNS \
	      [list "SOAP-ENC" "http://schemas.xmlsoap.org/soap/encoding/"]
	  $obj registerEnc "http://schemas.xmlsoap.org/soap/encoding/"
	}\
	-instproc SoapHeader {obj} {
	  my instvar invocationContext
	  $invocationContext instvar data
	  my debug HEADER=[array get data]
	  set fields [list]
	  foreach {key value} [array get data] {
	    append fields [subst {
	      ::xosoap::marshaller::SoapHeaderField new \
		  -elementName $key \
		  -value $value
	    }]
	  }
	  if {$fields ne {}} {
	    $obj contains $fields
	  }
	}
    Class InboundResponse \
	-instproc SoapBodyResponse {obj} {
	  my instvar invocationContext
	  $invocationContext unmarshalledResponse [$obj responseValue]
	}
  }

  
  AggregationClass RpcLiteral -contains {
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
	    set any [::xosoap::xsd::XsAnything new -isVoid__ true]
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
	  my instvar serviceMethod serviceArgs \
	      invocationContext
	  my debug CALL=[$obj elementName]
	  $invocationContext virtualCall [$obj elementName]
	  #set tmpArgs ""
	  #foreach keyvalue [$obj set methodArgs]  {	 
	  #  append tmpArgs " " "{[lindex $keyvalue 1]}"     
	  #}     
	  $invocationContext virtualArgs [$obj set methodArgs]
	}
    Class OutboundResponse \
      -instproc SoapBodyResponse {obj} {
	my instvar invocationContext
	#$obj class ::xosoap::marshaller::SoapBodyResponse
	$obj elementName [$invocationContext virtualCall]Response
	$obj set style [[self class] info parent]
	$obj responseValue [my batch]
      }
    Class OutboundRequest \
	-instproc SoapBodyRequest {obj} {
	  my instvar invocationContext
	  $obj elementName [$invocationContext virtualCall]
	  $obj set methodArgs [$invocationContext virtualArgs]
	  $obj set style [[self class] info parent]
	  my debug METHODARGS=[$obj set methodArgs]
	  set ns [$invocationContext getCallNamespace]
	  if {$ns ne {}} {
	    array set tmp $ns
	    $obj elementNamespace $tmp(prefix)
	    $obj registerNS [list $tmp(prefix) $tmp(uri)]
	    if {$tmp(prefix) eq {}} {
	      # -- is default namespace
	      # -- clear for prefixed namespaces
	      $obj unregisterNS "m"
	    } 
	  }
	  # if {[$invocationContext exists callNamespace]} {
	  # 	    # / / / / / / / / / / / / / / /
	  # 	    # TODO: default namespace support!!!!!
	  # 	    $obj registerNS [list "m" [$invocationContext callNamespace]]
	  # 	  } 
	}\
	-instproc SoapHeader {obj} {
	  my instvar invocationContext
	  $invocationContext instvar data
	  my debug HEADER=[array get data]
	  set fields [list]
	  foreach {key value} [array get data] {
	    append fields [subst {
	      ::xosoap::marshaller::SoapHeaderField new \
		  -elementName $key \
		  -value $value
	    }]
	  }
	  if {$fields ne {}} {
	    $obj contains $fields
	  }
	}
    Class InboundResponse \
	-instproc SoapBodyResponse {obj} {
	  my instvar invocationContext
	  $invocationContext unmarshalledResponse [$obj responseValue]
	}
  }
  
  AggregationClass DocumentLiteral -contains {
    Class SoapMarshallerVisitor \
	-instproc SoapBodyResponse {obj} {
	  my instvar xmlDoc parentNode
	  $obj instvar __node__
	  if {[$obj responseValue] eq {}} {
	    set any [::xosoap::xsd::XsAnything new -isVoid__ true]
	  } else {
	    set any [$obj responseValue]
	  }
	  $any marshal $xmlDoc $__node__ $obj
	}
    Class InboundRequest \
	-instproc SoapBodyRequest {obj} {
	  my instvar serviceMethod serviceArgs \
	      invocationContext
	  my debug CALL=[$obj elementName]
	  # / / / / / / / / / / / / / / / / /
	  # resolve call from SOAPAction
	  # header (as necessary in D/L style)
	  set actionUrl [$invocationContext action]
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
	  $invocationContext virtualCall [lindex $urlv end]
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
	  set any [::xorb::datatypes::Anything new -name__ "parameters"]
	  foreach a [$obj set methodArgs] {
	    $any add -parse $a
	  }
	  $invocationContext virtualArgs $any
	}
	  
    Class OutboundResponse \
	-instproc SoapBodyResponse {obj} {
	  #my instvar invocationContext
	  #$obj class ::xosoap::marshaller::SoapBodyResponse
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
      LoggingInterceptor SoapInvocationContext RpcLiteral DocumentLiteral \
      RpcEncoded
}


