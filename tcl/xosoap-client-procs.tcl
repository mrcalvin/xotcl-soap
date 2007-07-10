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
  

  # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # #
  # SoapGlueObject
  # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # #

  ContextObjectClass SoapGlueObject -slots {
    Attribute callNamespace
    Attribute schemas
    Attribute action
    Attribute marshalledRequest
    Attribute marshalledResponse
    Attribute unmarshalledRequest
    Attribute unmarshalledResponse
    Attribute messageStyle -default ::xosoap::RpcLiteral
  } -superclass ContextObject \
      -clientPlugin ::xosoap::client::Soap::Client
  SoapGlueObject instforward endpoint %self virtualObject
  
  # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # #
  # Soap Client handler
  # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # #

  ::xotcl::Class Soap::Client 
  Soap::Client instproc handleRequest {invocationContext} {
    
    namespace import ::xosoap::visitor::*
    namespace import ::xosoap::marshaller::*
    # / / / / / / / / / / / /
    # 1) initiate marshalling
    
    # 1.1) construe SOAP request object structure
    set requestEnvelope [SoapEnvelope new]
    
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
  Soap::Client instproc handleResponse {invocationContext} {
    namespace import ::xosoap::visitor::*
    namespace import ::xosoap::marshaller::*
    # / / / / / / / / / / / /
    # 1) initiate demarshalling

    set responseEnvelope [::xosoap::marshaller::SoapEnvelope new -response]
    set doc [dom parse [$invocationContext marshalledResponse]]
    set root [$doc documentElement]
    $responseEnvelope parse $root
    # (6) return invocation results
    set responseVisitor [InvocationDataVisitor new \
			     -volatile \
			     -invocationContext $invocationContext]
    # / / / / / / / / / / / / /
    # populates context object
    # with unmarshalled response
    $responseVisitor releaseOn $responseEnvelope
    # / / / / / / / / / / / /
    # 2) forward to request handler
    next $invocationContext
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
    set actionHeaderValue [expr {[$invocationObject exists action]?\
				     [$invocationObject action]:$url}]
    my log postData=$postData
    set rObj [::xo::HttpRequest new \
		  -url $url \
		  -post_data $postData \
		  -content_type "text/xml" \
		  -request_header_fields [list SOAPAction $actionHeaderValue]]
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
	my log FAULT=[$envelope serialize]
	# / / / / / / / / / / / / / / / /
	# cast into local error message
	# or rather exception type!
	set fv [::xosoap::visitor::FaultDataVisitor new -volatile]
	$envelope accept $fv
	set exception [CaughtFaultException new [$fv data]]
      } catch {error e} {
	global errorInfo
	error [HttpTransportProviderException new [subst {
	  Recasting a SOAP fault message into a local
	  exception failed due to '$errorInfo'
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
    } else {
      my log data=[$rObj set data]
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
  } -clientPlugin ::xosoap::client::Soap::Client 

  ContextObjectClass SoapClass -superclass {
    SoapGlueObject
    ProxyClass
  } -clientPlugin ::xosoap::client::Soap::Client \
      -instproc init args {
	my superclass add ::xosoap::client::SoapObject
      }
  
  namespace export SoapGlueObject HttpTransportProvider \
      SoapObject SoapClass

}	


