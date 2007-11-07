ad_library {
    
  xosoap-specific exception types,
  extending xoexception and xorb's exception facilities
  
  @author stefan.sobernig@wu-wien.ac.at
  @creation-date December 1, 2006
  @cvs-id $Id$
  
}

namespace eval ::xosoap::exceptions {

  namespace import -force ::xoexception::*
  namespace import -force ::xorb::exceptions::*
 
  ::xotcl::Class Returnable -parameter {
	returnCmd
	statusCode
        contentType
   }
  Returnable instproc write {packageObj} {
    next;#log first
    #my log "---ser=[my serialize]"
    my instvar __message__ node
    set __message__(text/plain) [$node asXML]
    foreach p [[self class] info parameter] {
      if {[my exists $p]} {
	my instvar $p
      } else {
	[my info class] instvar $p
      }
    }
    #my debug "---vars=[info vars],packageObj=$packageObj"
    set msg "$__message__($contentType)"
    $packageObj $returnCmd $statusCode $contentType $msg
  }
 
  ::xotcl::Class ReturnableException -superclass LoggableException  \
      -parameter {
	{returnCmd returnException}
	{statusCode "200"}
	{contentType "text/plain"}
      }
  ReturnableException instproc init args {
    my instmixin add ::xosoap::exceptions::Returnable
    next
  }

  # # # # # # # # # # # # #
  # # # # # # # # # # # # #
  # # Mixin: Faultable 
  # # # # # # # # # # # # #
  # # # # # # # # # # # # #

  ::xotcl::Class Faultable
  Faultable instproc init args {
    next; # call Loggable-> init first!
  }
  Faultable instproc write args {
    namespace import -force ::xosoap::marshaller::*
    namespace import -force ::xosoap::visitor::*
    my instvar node
    set class [namespace tail [my info class]]
    set fcode [expr {[my category] ne {} ? \
			 "[my category].$class":$class}]
    # / / / / / / / / / / / / / / /
    # 1) Envelope + SoapFault object
    set env [SoapEnvelope new -nest [subst {
      ::xosoap::marshaller::SoapFault new \
	  -faultcode xosoap:$fcode \
	  -faultstring {[[my info class] set __classDoc__]} \
	  -detail {[$node asXML]}
    }]]
    # / / / / / / / / / / / / / / /
    # 2) marshalling
    set visitor [SoapMarshallerVisitor new -volatile]
    $visitor releaseOn $env
    my set __message__(text/xml) [[$visitor xmlDoc] asXML]
    next
  }

  # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # #
  # # Meta class: FaultableException 
  # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # #

  ::xotcl::Class FaultableException -superclass ReturnableException

  FaultableException instproc init args {
    my statusCode 500
    my contentType "text/xml"
    my instmixin add ::xosoap::exceptions::Faultable
    next
  }
 
  # / / / / / / / / / / / / / / / / / / / / / / / / /
  # Exception types + documentation
  ReturnableException MalformedEndpointException -ad_doc {
    Endpoint address is malformed
  } -statusCode 404

  ReturnableException HttpRequestException -ad_doc {
    Non-acceptable request
  } -statusCode 406 

  ReturnableException UIRequestException -ad_doc {
    An user interface request failed.
  }

  ReturnableException UnknownUIRequestException -ad_doc {
    An user interface request failed due to an unknown reason.
  }

  ReturnableException UnknownException -ad_doc {
    An unspecified exception was caught
  } -statusCode 500

  ReturnableException WsdlGenerationException -ad_doc {
    The generation of a WSDL document failed.
  } -statusCode 500
  
  # / / / / / / / / / / / / / / / / / / / / / / / / /
  # Client exception types + documentation

  LoggableException HttpTransportProviderException -ad_doc {
    An exception was triggered at the level of the
    Http transport provider
  }

  LoggableException CaughtFaultException -ad_doc {
    A fault message was retrieved from the server/
    provider
  }

  LoggableException InvocationScenarioException \
      -ad_doc {
	Current scenario of invocation could not be derived from
	invocation context.
      }
  
  
  # / / / / / / / / / / / / / / / / / / / / / / / / /
  # SoapFaults (categories) + documentation
  
  Class Server -contains {
    # / / / / / / / / / / / / / / / / / / / / / / / / /
    # fault category: Server.*
    ::xosoap::exceptions::FaultableException UnknownInvocationException \
	-ad_doc {
	  Dispatching the virtual method call by the Invoker failed
	  for an unknown reason.
	}
    
    ::xosoap::exceptions::FaultableException InvocationException \
	-ad_doc {
	  Dispatching the virtual method call by the Invoker failed
	}

    ::xosoap::exceptions::FaultableException MalformedNamespaceDeclaration \
	-ad_doc {
	  The call to register a new namespace was passed malformed arguments.
	}

    ::xosoap::exceptions::FaultableException DemarshallingException \
	-ad_doc {
	  An exception occurred when attempting to demarshal the 
	  SOAP payload.
	}

    ::xosoap::exceptions::FaultableException MarshallingException \
	-ad_doc {
	  An exception occurred when attempting to marshal the 
	  SOAP response.
	}


    ::xosoap::exceptions::FaultableException ContextInitException \
	-ad_doc {
	  The initialisation of an invocation context object failed.
	}

    # / / / / / / / / / / / / / / / / / / / / / / / / /
  
  }

  Class Client -contains {
    
    # / / / / / / / / / / / / / / / / / / / / / / / / /
    # fault category: Client.*
    ::xosoap::exceptions::FaultableException InvalidSoapEncodingException \
	-ad_doc {
	  Demarshalling failed due to unsupported (custom) encoding scheme
	  detected. Currently, only the SOAP (1.1) encoding and XS 1.1
	  encoding scheme are supported. This includes failures due to violated 
	  compound typing rules (i.e. 'by-precedence typing' in case of Arrays).
	}

    ::xosoap::exceptions::FaultableException SoapHttpRequestException \
	-ad_doc {
	  Your HTTP request did not conform to the requirements
	}
  }


  
  namespace export MalformedEndpointException HttpRequestException \
      ReturnableException UnknownException Server Client \
      HttpTransportProviderException WsdlGenerationException \
      CaughtFaultException UIRequestException UnknownUIRequestException
}
