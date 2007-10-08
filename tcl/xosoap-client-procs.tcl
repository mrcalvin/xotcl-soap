ad_library {

  
  @author stefan.sobernig@wu-wien.ac.at
  @creation-date August, 23 2006
  @cvs-id $Id$

}

namespace eval xosoap::client {

  namespace import -force ::xosoap::*
  namespace import -force ::xorb::stub::*
  namespace import -force ::xorb::client::*
  namespace import -force ::xoexception::try
  namespace import -force ::xosoap::exceptions::*
  

  # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # #
  # SoapGlueObject
  # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # #

  ContextObjectClass SoapGlueObject -slots {
    Attribute callNamespace
    Attribute schemas
    Attribute messageStyle -default ::xosoap::RpcLiteral
  } -instproc init args {
    my protocol ::xosoap::Soap
    next
  } -ad_doc {
    <p>
    The class SoapGlueObject refines <a href="show-object?show%5fmethods=1&show%5fsource=0&object=%3a%3axorb%3a%3astub%3a%3aContextObject">ContextObject</a>
    to provide necessary configuration parameters for the SOAP
    protocol plug-in, or rather client proxies defined in its scope.
    </p>

    <p>
    The class adds the following properties (attribute slots) 
    to those of <a href="show-object?show%5fmethods=1&show%5fsource=0&object=%3a%3axorb%3a%3astub%3a%3aContextObject">ContextObject</a>:
    <ul>
    <li>
    endpoint: Simple delegate for ContextObject->virtualObject
    that takes the transport endpoint of the targeted SOAP service.
    </li>
    <li>callNamespace: Allows to add a namespace URI that is 
    then bound to the namespace prefix of the request element 
    in the body part of the SOAP message.</li>
    <li>schemas: By providing a list of prefix/URI pairs to this
    property, one may register custom namespaces to be streamed
    into the SOAP request message.</li>
    <li>
    action: Explicitly provide a value to the HTTP header field "SOAPAction".
    It defaults to the endpoint address.
    </li>
    <li>
    messageStyle: Specify the (de-)marshaling style to be used, you may
    choose between ::xosoap::{RpcEncoded|RpcLiteral|DocumentLiteral}.
    </li>
    <li>
    marshalledRequest: Depending on the execution stage, contains the
    streamed version of the SOAP request message.
    </li>
    marshalledResponse: Depending on the execution stage, contains the
    streamed version of the SOAP response message.
    <li>
    unmarshalledRequest: Depending on the execution stage, contains the
    objectified version of the SOAP request message. It is a composite 
    structure of XOTcl objects of type <a href="">SoapElement</a> that
    can easily be traversed.
    </li>
    <li>
    unmarshalledResponse: Depending on the execution stage, contains the
    objectified version of the SOAP response message. It is a composite 
    structure of XOTcl objects of type <a href="">SoapElement</a> that
    can easily be traversed.
    </li>
    </ul>
    </p>

    @author stefan.sobernig@wu-wien.ac.at
  } -superclass ContextObject \
      -clientPlugin ::xosoap::Soap::Client

  SoapGlueObject instproc getCallNamespace {} {
    my instvar callNamespace
    if {![info exists callNamespace]} return;
    array set tmp {
      prefix 	""
      uri	""
    }
    switch [llength $callNamespace] {
      1 {
	# -- default per-element namespace
	set tmp(uri) $callNamespace
      }
      2 {
	# -- prefixed per-element namespace
	set tmp(prefix) [lindex $callNamespace 0]
	set tmp(uri) [lindex $callNamespace 1]
      }
      default return;
    }
    return [array get tmp]
  }
  SoapGlueObject instproc setHttpHeader {field value} {
    my instvar httpHeader
    set httpHeader($field) $value
  }
  SoapGlueObject instproc getHttpHeader {field} {
    my instvar httpHeader
    if {[info exists httpHeader($field)]} {
      return $httpHeader($field)
    }
  }
  SoapGlueObject instforward action -default {getHttpHeader setHttpHeader} %self %1 SOAPAction 
  SoapGlueObject instforward endpoint %self virtualObject
  
  # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # #
  # Soap Client handler
  # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # #

  ::xotcl::Class ::xosoap::Soap::Client 
  ::xosoap::Soap::Client instproc handleRequest {invocationContext} {
    
    namespace import ::xosoap::visitor::*
    namespace import ::xosoap::marshaller::*
    # / / / / / / / / / / / /
    # 1) initiate marshalling
    
    # 1.1) construe SOAP request object structure
    # / / / / / / / / / / / / / /
    # Introducing header?
    if {[$invocationContext exists data]} {
      set requestEnvelope [SoapEnvelope new -header]
    } else {
      set requestEnvelope [SoapEnvelope new]
    }
    
    # 1.2) populate SOAP request object 
    set requestVisitor [InvocationDataVisitor new \
			    -volatile \
			    -invocationContext $invocationContext]
    $requestVisitor releaseOn $requestEnvelope
    $invocationContext unmarshalledRequest $requestEnvelope
    # 1.3) employ / adapt SoapMarshallerVisitor
    set marshaller [SoapMarshallerVisitor new -volatile]
    $marshaller releaseOn $requestEnvelope
    # 1.4) store marshalled request/ payload with context
    set payload [[$marshaller xmlDoc] asXML]
    $invocationContext marshalledRequest $payload
    # / / / / / / / / / / / /
    # 2) forward to request handler
    next $invocationContext
  }
  ::xosoap::Soap::Client instproc handleResponse {invocationContext} {
    namespace import ::xosoap::visitor::*
    namespace import ::xosoap::marshaller::*
    
    # / / / / / / / / / / / / / / /
    # Demarshaling was handled
    # before, no need to do it now!
    if {![$invocationContext exists unmarshalledResponse]} {
      # / / / / / / / / / / / /
      # 1) initiate demarshalling
      
      set responseEnvelope [::xosoap::marshaller::SoapEnvelope new -response true]
      set doc [dom parse [$invocationContext marshalledResponse]]
      set root [$doc documentElement]
      $responseEnvelope parse $root
      $invocationContext unmarshalledResponse $responseEnvelope
    }
    # / / / / / / / / /
    # ctx represents the
    # possibly mangled
    # invocation context
    # from the client request 
    # handler
    set ctx [next]
    # (6) return invocation results
    my debug CTX=[$ctx serialize]
    set responseVisitor [InvocationDataVisitor new \
			     -volatile \
			     -invocationContext $ctx]
    # / / / / / / / / / / / / /
    # populates context object
    # with unmarshalled response
    $responseVisitor releaseOn [$ctx unmarshalledResponse]
    return $ctx
    # / / / / / / / / / / / /
    # 2) forward to request handler
  }
  
  # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # #
  # Http transport provider
  # based on xotcl-core
  # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # #
  
  ::xotcl::Class HttpTransportProvider \
      -superclass TransportProvider \
      -set key "http"

  HttpTransportProvider instproc handle {invocationObject} {
    namespace import -force ::xosoap::exceptions::*
    set postData [$invocationObject marshalledRequest]
    set url http://[$invocationObject virtualObject]
    array set headers [list]
    # -- process headers
    foreach field [$invocationObject array names httpHeader] {
      set headers($field) [$invocationObject getSubstified httpHeader($field)]
    }
    # -- some defaults
    if {![info exists headers(SOAPAction)]} {
      set headers(SOAPAction) $url
    }
    my debug postData=$postData
    set rObj [::xo::HttpRequest new \
		  -url $url \
		  -post_data $postData \
		  -content_type "text/xml" \
		  -request_header_fields [array get headers]]
    # handling of exception situations
    # http status code 500
    if {[$rObj exists statusCode] && [$rObj set statusCode] eq 500} {
      # handle as fault
      try {
	set faultMsg [$rObj set data] 
	set envelope [::xosoap::marshaller::SoapEnvelope new \
			  -nest {
			    ::xosoap::marshaller::SoapFault new
			  }]
	set doc [dom parse $faultMsg]
	set root [$doc documentElement]
	$envelope parse $root
	my debug FAULT=[$envelope serialize]
	# / / / / / / / / / / / / / / / /
	# cast into local error message
	# or rather exception type!
	set fv [::xosoap::visitor::FaultDataVisitor new -volatile]
	$envelope accept $fv
	set exception [CaughtFaultException new [$fv data]]
      } catch {error e} {
	#global errorInfo
	error [HttpTransportProviderException new [subst {
	  Recasting a SOAP fault message into a local
	  exception failed due to '$e'
	}]]
      }
      if {[info exists exception]} {
	error $exception
      }
    } elseif {[$rObj exists statusCode] && [$rObj set statusCode] ne 200} {
      # encapsulate arbitrary http error messages
      error [HttpTransportProviderException new [subst {
	Http request transport did not suceed with 
	status code [$rObj set statusCode] and message '[$rObj set data]'
      }]]
    } elseif {[$rObj set data] eq {}} {
      # encapsulate arbitrary http error messages
      error [HttpTransportProviderException new [subst {
	No response data was received, this might be due
	to errorneous connections or failure of establishing
	a connection as such.
      }]]
    } else {
      my debug data=[$rObj set data]
      return [$rObj set data]

    }
  }

  # / / / / / / / / / / / / / / / / /
  # / / / / / / / / / / / / / / / / /
  # Experimental: A third layer of
  # the stub/ client interface which
  # is plug-in specific. It combines
  # glue object and client proxy in one!
  # The proxy is used as glue/context object
  # (lately bound) by the requestor.

  ContextObjectClass SoapObject -superclass {
    SoapGlueObject
    ProxyObject
  } -ad_doc {
    <p>The class provides a high-level interface to create
    SOAP-enabled client proxies in xorb/xosoap. It integrates
    both capabilities + features of <a href="show-object?show%5fmethods=1&show%5fsource=0&object=::xorb::stub::ProxyObject">ProxyObject</a> and
    <a href="show-object?show%5fmethods=1&show%5fsource=0&object=::xosoap::client::SoapGlueObject">SoapGlueObject</a>. Instances are pure XOTcl objects
    and do not inherit from ::xotcl::Class, so can't be instantiated further.
    If you wish or feel the need to of a a SOAP-enabled client proxy that
    behaves like a class, watch out for <a href="show-object?show%5fmethods=1&show%5fsource=0&object=::xosoap::client::SoapClass">SoapClass</a>.
    </p>
    
    @author stefan.sobernig@wu-wien.ac.at
  } -clientPlugin ::xosoap::Soap::Client




  ContextObjectClass SoapClass -superclass {
    SoapGlueObject
    ProxyClass
  } -ad_doc {
    <p>The class provides a high-level interface to create
    SOAP-enabled client proxies in xorb/xosoap. It integrates
    both capabilities + features of <a href="show-object?show%5fmethods=1&show%5fsource=0&object=::xorb::stub::ProxyObject">ProxyObject</a> and
    <a href="show-object?show%5fmethods=1&show%5fsource=0&object=::xosoap::client::SoapGlueObject">SoapGlueObject</a>. Instances are XOTcl classes
    and can be instantiated further. By using SoapClass, you can create
    a crowd of instances being actual client proxies, all using the information
    provided by the SoapClass object. If you wish or feel the need to of a 
    SOAP-enabled client proxy that behaves like a pure object, watch out for
    <a href="show-object?show%5fmethods=1&show%5fsource=0&object=::xosoap::client::SoapObject">SoapObject</a>.
    </p>
    @author stefan.sobernig@wu-wien.ac.at
  } -clientPlugin ::xosoap::Soap::Client \
      -instproc init args {
	my superclass add ::xosoap::client::SoapObject
      }
  
  # / / / / / / / / / / / / / / / /
  # Mixin class CachingInterceptor
  # - - - - - - - - - - - - - - - -
  SoapInterceptor CachingInterceptor
  
  CachingInterceptor instproc handleRequest {context} {
    my instvar requestHandler
    # / / / / / / / / / / / / / / / / /
    # 1-) Fetch object identifier:
    # We preserve the object identifier (uri)
    # in the pre-roundtrip scope (request
    # handler) as it might be modified
    # by other interceptors or the dispatcher.
    my instvar id
    set id [$context virtualObject]
    # / / / / / / / / / / / / / / / / 
    # 2-) In a second step, verify 
    # that there is no cache entry for
    # the given object identifier.
    set exists [expr {[ns_cache names xotcl_object_cache $id] eq ""?0:1}]
    if {$exists} {
      # / / / / / / / / / / / / / / /
      # 2.1-) If the request matches a
      # cached entry, provide for 
      # initialisation of cached object 
      # and indirect request handler flow
      set code [ns_cache get xotcl_object_cache $id]
      set uncache ::[::xotcl::Object autoname cachedMessage]
      eval [lindex $code 1]
      # / / / / / / / / / / / / / / /
      # 2.1.1-) Both, the serialised and
      # deserialised states are cached.
      # We populate the context object
      # accordingly.
      $context unmarshalledResponse $uncache
      $context marshalledResponse [lindex $code 0]
      # / / / / / / / / / / / / / / /
      # 2.1.2-) We tag this roundtrip as
      # 'sourced-from-cache'. As the
      # following indirection will also
      # invoke this interceptor on the
      # response flow, we want to easily
      # distinguish the need to intercept.
      my set cached_and_indirected 1
      # / / / / / / / / / / / / / / /
      # 2.1.3-) indirect call to response
      # flow
      $requestHandler handleResponse $context
    } else {
      # / / / / / / / / / / / / / / /
      # 2.2-) No matching cache entry
      # exists, proceed in request 
      # flow
      next;# next interceptor
    }
  }
  CachingInterceptor instproc handleResponse {context} {
    # / / / / / / / / / / / / / / /
    # 1-) Is the interceptor (on the
    # response flow) called from an 
    # indirected request or from a
    # remotely served one?
    my instvar cached_and_indirected id
    if {![info exists cached_and_indirected]} {
      # / / / / / / / / / / / / / / /
      # 1.1-) If the request in the roundtrip
      # was not intercepted, make sure that
      # the response (which actually comes
      # from a remote end) is cached.
      ns_cache eval xotcl_object_cache $id {
	set mapping [subst {[$context unmarshalledResponse] \${uncache}}]
	set stream [::Serializer deepSerialize [$context unmarshalledResponse]\
			-map $mapping]
	return [list [$context marshalledResponse] ]
      }
    }
    next;# next interceptor
  }
  # - register caching interceptor
  ::xorb::client::consumer_chain add [CachingInterceptor self]



  namespace export SoapGlueObject HttpTransportProvider \
      SoapObject SoapClass CachingInterceptor

}	


