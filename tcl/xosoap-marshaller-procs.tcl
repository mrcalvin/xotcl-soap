ad_library {
   
    <p>Library providing specific SOAP parsing facilities:</p>
    <p>
    <ul>
    	<li>The <bold>Marshaller</bold> offers a (<a href='/api-doc/proc-view?proc=::xosoap::marhsaller::Marshaller+instproc+demarshal'>demarshalling</a>) and (<a href='/api-doc/proc-view?proc=::xosoap::marhsaller::Marshaller+instproc+marshal'>marshalling</a>) facility for SOAP messages</li>
    	<li>Parsing SOAP messages into a <bold>Soap Syntax Tree</bold> reflecting the Composite (<a href='/xotcl/show-object?object=::xosoap::marhsaller::Composite'>Composite</a>) and Chain of Responsibility Patterns (for namespace handling, see <a href='/xotcl/show-object?object=::xosoap::marhsaller::SoapNamespace'>SoapNamespace</a>).</li>
    	<li>An OO facility for <a href='/xotcl/show-object?object=::xosoap::marhsaller::SoapFault'>SOAP Faults</a> that encapsulate <a href='/xotcl/show-object?object=::xosoap::Exception'>xoSoap's exceptions</a> when requested.</li>
    	   	
    </ul>
    </p>
    

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August 18, 2005
    @cvs-id $Id$

  
}


namespace eval xosoap::marshaller {

####################################################
# xoSoap message context
####################################################


::xotcl::Class MessageContext -parameter {
    soapVersion 
    requestMessage 
    responseMessage    
} -ad_doc {

	<p>The class provides a common container for a SOAP request and its corresponding SOAP response. The Invoker creates such a container for each disembarking request and passes it along the way down the process of demarshalling and invocation, then up again through demarshalling.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005 
	
	}

::xotcl::Class RequestMessage -parameter {soapEnvelope} -ad_doc {

	<p>A container element representing the SOAP request.</p>
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005 
	}
	
::xotcl::Class ResponseMessage -parameter {soapEnvelope} -ad_doc {

	<p>A container element representing the SOAP response.</p>
	
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005 
	
	}

####################################################
# xoSoap Marshaller
####################################################

::xotcl::Class Marshaller -ad_doc {

    <p>Provides (de-) marshalling facilities for SOAP/XML 1.1/ 1.2 based on tDOM. 
    At least inspired by the Soap Gateway code pioneered by William Byrne 
    (WilliamB@ByrneLitho.com) and re-casted by Nick Carroll 
    (ncarroll@ee.usyd.edu.au). </p>
    <p>
    The marshaller operates over the generated SOAP syntax tree by having adequate visitors
    crawling it to extract invocation infos (see <a href='/xotcl/show-object?object=::xosoap::visitor::SoapDemarshallerVisitor'>xosoap::visitor::SoapDemarshallerVisitor</a>) and or marshal SOAP responses (see <a href='/xotcl/show-object?object=::xosoap::visitor::SoapMarshallerVisitor'>xosoap::visitor::SoapMarshallerVisitor</a>).	
    </p>

    @author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005 
}

Marshaller ad_instproc init args {} {
    
    my set msgCtx {}

}

Marshaller ad_instproc marshal { msgContext returnValue } {

	<p>It creates a visitor instance of type <a href='/xotcl/show-object?object=::xosoap::visitor::SoapMarshallerVisitor'>xosoap::visitor::SoapMarshallerVisitor</a> and releases
	the visitor on the Soap syntax tree that serves as blueprint for the serialized response message. The final Soap message
	is then attached to the message context as parameter.</p>
		
    @author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005
	
	@param msgContext The corresponding message context object that represents the entire conversation.
	@param returnValue The actual return value of the invocation process. It is passed to <a href='/api-doc/proc-view?proc=::xosoap::visitor::SoapMarshallerVisitor+instproc+releaseOn'>xosoap::visitor::SoapMarshallerVisitor releaseOn</a> to be injected into the SOAP response.
	
	@return An object of type <a href='/xotcl/show-object?object=::xosoap::marshaller::MessageContext'>::xosoap::marshaller::MessageContext</a> that carries the Soap syntax tree representing the Soap request and the serialized Soap response.
	
	@see <a href='/xotcl/show-object?object=::xosoap::visitor::SoapMarshallerVisitor'>xosoap::visitor::SoapMarshallerVisitor</a>
	@see <a href='/api-doc/proc-view?proc=::xosoap::visitor::SoapMarshallerVisitor+instproc+releaseOn'>xosoap::visitor::SoapMarshallerVisitor releaseOn</a>

} {

    my instvar msgCtx
    my set msgCtx msgContext

    ::xosoap::visitor::SoapMarshallerVisitor mv
    mv releaseOn [[$msgCtx requestMessage] soapEnvelope] $returnValue
    $msgCtx responseMessage [mv xmlDoc]
    return $msgCtx

}

Marshaller ad_instproc demarshal { msgContext soapxmlRequest } {


	<p>First, it creates a root object of a new Soap syntax tree and hands over the serialized Soap request for parsing. It then instantiates a visitor of type <a href='/xotcl/show-object?object=::xosoap::visitor::SoapDemarshallerVisitor'>xosoap::visitor::SoapDemarshallerVisitor</a> and releases
	the visitor on the Soap syntax tree to isolate essential invocation infos, i.e. the remote procedure called and arguments enclosed. The resulting composite of soap element objects is then stored in the respective message context.</p>
		
    @author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005
	
	@param msgContext The <a href='/xotcl/show-object?object=::xosoap::marshaller::MessageContext'>message context object</a> just created by the Invoker.
	@param soapxmlRequest The serialized SOAP payload as extracted by the <a href='/xotcl/show-object?object=::xosoap::RequestMessageHandler'>xosoap::RequestMessageHandler</a>.
	
	@return An object of type <a href='/xotcl/show-object?object=::xosoap::marshaller::MessageContext'>::xosoap::marshaller::MessageContext</a> that carries the Soap syntax tree representing the Soap request.
	
	@see <a href='/xotcl/show-object?object=::xosoap::visitor::SoapMarshallerVisitor'>xosoap::visitor::SoapMarshallerVisitor</a>
	@see <a href='/api-doc/proc-view?proc=::xosoap::visitor::SoapMarshallerVisitor+instproc+releaseOn'>::xosoap::visitor::SoapMarshallerVisitor releaseOn</a>
	@see <a href='/xotcl/show-object?object=::xosoap::marshaller::MessageContext'>::xosoap::marshaller::MessageContext</a>
	

} {

    my instvar msgCtx
    set msgCtx msgContext

    set doc [dom parse $soapxmlRequest]
    set root [$doc documentElement]

    set envelope [SoapEnvelope envelope]
    
    envelope parse $root
    
    ::xosoap::visitor::SoapDemarshallerVisitor dv

    dv releaseOn $envelope
    
    set rqMessage [::xosoap::marshaller::RequestMessage rqMessage]
    rqMessage soapEnvelope $envelope
    msgContext requestMessage $rqMessage
    msgContext soapVersion [my getSoapVersion envelope]

    my debug "Demarshalled SOAP message:	\n\t	encodingStyle: [envelope encodingStyle] 
					\n\t	envelopeNS: [envelope nsEnvelopeVersion] 
					\n\t	soapVersion: [msgContext soapVersion]					
					\n\t	method: [dv serviceMethod]
					\n\t	args: [dv serviceArgs]"

    return msgContext

}

Marshaller ad_instproc -private true getSoapVersion { soapEnvelope } {

	<p>Helps identify the SOAP standard's version the incoming and parse SOAP request adheres to. Therefore, it verifies both the encoding and envelope namespaces attached to the SOAP request. If there is a version mismatch between the two, a general fallback to the envelope's version is provided. Reference values for the version namespaces are taken from the <a href='http://www.w3.org/TR/2000/NOTE-SOAP-20000508/\#_Toc478383495'>SOAP 1.1</a> and <a href='http://www.w3.org/TR/2003/REC-soap12-part1-20030624/\#soapenv'>SOAP 1.2</a> spec.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005
	
	@param soapEnvelope The SOAP tree of objects which also stores encoding and envelope version information, i.e. the namespace URIs extracted from the SOAP request.
	@return A Tcl string representing the SOAP version on hand. Return value is either "1.1" or "1.2".
	
	@see <a href='/xotcl/proc-view?proc=::xosoap::marhsaller::Marshaller+instproc+demarshal'>::xosoap::marhsaller::Marshaller demarshal</a>
	
	


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

###############################################
#Simple filter-based composite meta-class
###############################################

::xotcl::Class Composite -superclass ::xotcl::Class -ad_doc {

	<p>SOAP envelopes are basically represented (XML) tree structures and therefore best represented as Composite structures in OO environments. XOTcl allows for straight-forward and simple usage of design patterns in this scenario. By making use of its meta-class construct, the filter interception technique and nested classes, the Composite meta-class implements the fundamentals of the Composite pattern. The approach adopted here is a slight adaptation from the composite example included in the XOTcl distribution (see patterns/composite.xotcl). The meta-class serves as skeleton for the class <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapElement'>::xosoap::marshaller::SoapElement</a>, the central building block for each SOAP-specific element in the syntax or object tree. It allows for passing specific, pre-defined method calls to each element of the composite structure without explicit recursive looping in a conventional parent-children manner.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005

}

Composite ad_instproc addOperations args {

	<p>By default, interception (and therefore composite redirection) by filters applies to all 
	methods defined on an object, e.g. <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapElement'>::xosoap::marshaller::SoapElement</a> and sub-classes thereof. However, only a limited number of operations, namely <a href='/api-doc/proc-view?proc=::xosoap::marshaller::SoapElement+instproc+accept'>accept</a> and <a href='/api-doc/proc-view?proc=::xosoap::marshaller::SoapElement+instproc+parse'>parse</a>, are intended to be affected. Therefore, filtering is only applied on explicitly identified methods, determined by adding them to a list of targeted methods.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005
	
	@param args A list of methods that should be directed through the composite structure.

} {

    foreach arg $args {
	foreach op $arg {
	    #puts $op
	    if {![my exists operations($op)]} {
		my set operations($op) $op
	    }
	}
    }
} 

Composite ad_instproc removeOperations args {

<p>Allows for removing methods from the list of operations that are meant to be executed over the entire composite structure.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005
	
	@param args A list of methods that should be removed from the list of filtered/ redirected operations.


} {
    foreach op $args {
	if {![my exists operations($op)]} {
	    my unset operations($op)
	}
    }
}

Composite ad_instproc compositeFilter args {

	<p>The actual filter method that is registered with each instance of <a href='/xotcl/show-object?object=::xosoap::marshaller::Composite'>::xosoap::marshaller::Composite</a> (see <a href='/api-doc/proc-view?proc=::xosoap::marshaller::Composite+instproc+init'>init</a>). First, it gets the actually called proc and verifies whether it is explicitly registered as operation to be forwarded. If so and provided that there are nested objects (children), it is passed to the them after being called on the current object itself.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005
	
	@param args The arguments of the originally called, intercepted method.

} {   
  


  set result [next]
  # get the operations class variable from the object's class
  set registrationclass [lindex [self filterreg] 0]
  $registrationclass instvar operations
  # get the request
  set r [self calledproc]
  #puts "$r on [self]"
  
  
  # check if the request is a registered operation 
  if {[info exists operations($r)]} {
    #puts "$r on [self]"
    
    foreach object [my info children] {	
      # forward request
	if {![$object istype SoapNamespace] && ![$object istype SoapEncoding]} {	
	    eval $object $r $args
	}
    }
  }
  return $result
}


Composite ad_instproc init args {

	
	<p>Upon intialisation, <a href='/api-doc/proc-view?proc=::xosoap::marshaller::Composite+instproc+init'>compositeFilter</a> is added to the list of filters attached to the new instance by calling instfilter.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005

} {
    
    my array set operations {}
    next
    my instfilter add compositeFilter 
}

###############################################
# SoapNamespace
###############################################

::xotcl::Class SoapNamespace -ad_doc {

	<p>An OO representation for namespaces attached to the various elements that a SOAP/XML envelope is made up by.
	Its instances act as namespace handlers with each SOAP element object having assigned a concrete handler. Each handler
	stores an array of prefix-uri pairs that apply to the corresponding SOAP element. Succeeding/ preceeding handlers are therefore detectable as within an object tree / composite of <a href='/xotcl/show-object?object=::marshaller::SoapElement'>SoapElements</a> inferring about parent-child relationsships is possible. This helps implement the Chain of responsibility pattern for namespace handler and therefore scope for validity of namespaces: As XML namespaces are valid for the current element level and, provided that there are no succeeding ones, for the its sub-tree, this allows to construct SOAP responses that inherit these dependencies/ namespace hierarchies from the initial SOAP request (see <a href='/xotcl/show-object?object=::xosoap::visitor::SoapMarshallerVisitor'>::xosoap::visitor::SoapMarshallerVisitor</a>).</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005

}

SoapNamespace ad_instproc init args {} {
  
  my array set nsArray {}
  
}

SoapNamespace ad_instproc add {prefix uri} {

	<p>
	By calling this method, a new prefix-uri pair can be added to the Namespace Handler of the current
	SOAP element object in the overall parsing process.
	</p>
	
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005
	
	@param prefix The namespace prefix as identified in the SOAP/XML request, , i.e. a "xmlns"-attribute.
	@param uri The namespace URI as identified in the SOAP/XML request, i.e. a "xmlns"-attribute.
	
	@see <a href='/api-doc/proc-view?proc=::xosoap::marshaller::SoapElement+instproc+registerNS'>::xosoap::marshaller::SoapElement registerNS</a>
	
} {

    my set nsArray($prefix) $uri

}

SoapNamespace ad_instproc get {prefix} {

	<p>
	Returns the namespace URI corresponding to the key represented by the prefix's value.
	</p>
	
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005
	
	@param prefix The namespace prefix as identified in the SOAP/XML request, , i.e. a "xmlns"-attribute.

} {

	return [lindex [my array get nsArray $prefix] 1]

}

SoapNamespace ad_instproc getPrefixes {} {

	<p>
	Returns all prefixes (keys) currently stored by the namespace handler.
	</p>
	
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005
	
	@return A list of namespace prefixes currently stored.

} {

	return [my array names nsArray]

}

###############################################
# SoapEncoding
###############################################
::xotcl::Class SoapEncoding -ad_doc {

	<p>The SOAP specs allow for varying encoding conventions to be assigned to an element and its sub-tree scope. Provided that an encodingStyle attribute is specified for an element, resolving the responsible convention for the element under consideration ressembles the Chain-of-Responsibility pattern (see also <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapNamespace'>::xosoap::marshaller::SoapNamespace</a>).</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date November, 2 2005

}

SoapEncoding ad_instproc init args {} {
  
  my set lstURI [list]
  
}

SoapEncoding ad_instproc add {encodingURI} {

	<p>Adds a new URI pointing to an encoding convention.</p>
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date November, 2 2005	
	@param encodingURI An URI string representing an encoding convention.
		
} {
	my instvar lstURI
    lappend lstURI $encodingURI

}

SoapEncoding ad_instproc get {} {

<p>Returns all URIs stored registered with the handler.</p>
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date November, 2 2005	
	@return An URI string representing an encoding convention.

} {
	my instvar lstURI
	return $lstURI
}

###############################################
# SoapElement
###############################################

Composite SoapElement -parameter {
    
    elementName
    elementNamespace
    namespaceHandler
    encodingHandler
     
} -ad_doc {

	On the one hand it derives from <a href='/xotcl/show-object?object=::marshaller::Composite'>::xosoap::marhaller::Composite</a>
	and therefore embodies the essential composite behaviour. On the other hand it serves as superclass for the concrete element object of the SOAP tree, such as <a href='/xotcl/show-object?object=::marshaller::SoapEnvelope'>::xosoap::marhaller::SoapEnvelope</a>, <a href='/xotcl/show-object?object=::marshaller::SoapHeader'>::xosoap::marhaller::SoapHeader</a> etc. Currently, it registers two methods that are then subject to redirection through the composite structure: <a href='/api-doc/proc-view?proc=::xosoap::marshaller::SoapElement+instproc+accept'>accept</a> and <a href='/api-doc/proc-view?proc=::xosoap::marshaller::SoapElement+instproc+parse'>parse</a>.

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005

}

SoapElement abstract instproc parse {rootNode}

SoapElement ad_instproc accept {visitor} {

	<p>The accept method of any SoapElement, i.e. sub-classes thereof, calls back a concrete visitor's visit method
	that passes the respective SoapElement to the visitor in order to perform some operations on the SoapElement object that are encapsulated in a concrete visitor object, e.g. <a href='/xotcl/show-object?object=::xosoap::visitor::SoapMarshallerVisitor'>::xosoap::visitor::SoapMarshallerVisitor</a> or <a href='/xotcl/show-object?object=::xosoap::visitor::SoapDemarshallerVisitor'>::xosoap::visitor::SoapDemarshallerVisitor</a>.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005
	
	@param visitor An object of type <a href='/xotcl/show-object?object=::xosoap::visitor::AbstractVisitor'>::xosoap::visitor::AbstractVisitor</a>


} {

    $visitor visit [self]
}

SoapElement addOperations "parse accept"

SoapElement ad_instproc resolveNSHandler {} {

	<p><This method helps realise what is referred to as Chain of Responsibility pattern for namespace handlers (see 
	<a href='/xotcl/show-object?object=::xosoap::marshaller::SoapNamespace'>::xosoap::marshaller::SoapNamespace</a>).
	If a namespace handler is affiliated with the current SoapElement, it is returned. Otherwise, the task to resolve a valid namespace handler is delegated to the parent object of the current SoapElement (Note that we move in a tree of nested objects).
	</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005
	
	@return Either an object of type <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapNamespace'>::xosoap::marshaller::SoapNamespace</a> or an empty string.

} {
 
  if {[my exists namespaceHandler]} {
    return [my set namespaceHandler]
  } else {
      #puts "[self] reports [my info parent]"
    set p [my info parent]
    if {$p != "::xosoap::marshaller"} {
      return [$p resolveNSHandler]
    } else {
      return ""
    }
  }
}

SoapElement ad_instproc registerNS {prefix uri} {

		<p>In the course of parsing a specific SoapElement (see e.g. <a href='/api-doc/proc-view?proc=::xosoap::marshaller::SoapEnvelope+instproc+parse'>::xosoap::marshaller::SoapEnvelope parse</a>) this method is called
		to <a href='/api-doc/proc-view?proc=::xosoap::marshaller::SoapElement+instproc+resolveNS'>resolve</a> the namespace handler valid in the scope of the current SoapElement. If there is no superordinated namespace handler, a new instance of <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapNamespace'>::xosoap::marshaller::SoapNamespace</a> is nested into the current SoapElement object and returned as the namespace handler responsible for <a href='/api-doc/proc-view?proc=::xosoap::marshaller::SoapNamespace+instproc+add'>adding</a> the prefix-uri pair.</p>

		@author stefan.sobernig@wu-wien.ac.at
		@creation-date August, 19 2005

		@param prefix The namespace prefix as identified in the SOAP/XML request, , i.e. a "xmlns"-attribute.
		@param uri The namespace URI as identified in the SOAP/XML request, i.e. a "xmlns"-attribute.

} {
  set ns [my resolveNSHandler]
   #my log "$ns <> [self]" 
  if {[string first [self] $ns] == -1} {
    set newNS [SoapNamespace create [self]::[my autoname ns]]
    my namespaceHandler $newNS
    set ns $newNS
  }
   #my log "adding Namespace $prefix:$uri at [self] istype [self class]"
  $ns add $prefix $uri
}

SoapElement ad_instproc resolveEncHandler {} {

	<p>It identifies the responsible encoding handler for the current <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapElement'>::xosoap::marshaller::SoapElement</a> in a Chain of Responsibility (see <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapNamespace'>::xosoap::marshaller::SoapNamespace</a> for further details).</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date November, 2 2005
	
	@return Either an object of type <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapEncoding'>::xosoap::marshaller::SoapEncoding</a> or an empty string.

} {
 
  if {[my exists encodingHandler]} {
    return [my set encodingHandler]
  } else {
     set p [my info parent]
    if {$p != "::xosoap::marshaller"} {
      return [$p resolveEncHandler]
    } else {
      return ""
    }
  }
}

SoapElement ad_instproc registerEnc {encodingURI} {

		<p>It provides for registering a encoding convention URI, as stored in the encodingStyle attribute, with a the encoding handler responsible for the current element.</p>

		@author stefan.sobernig@wu-wien.ac.at
		@creation-date November, 2 2005

		@param encodingURI An URI string pointing to an encoding convention.

} {
  set enc [my resolveEncHandler]
   #my log "$ns <> [self]" 
  if {[string first [self] $enc] == -1} {
    set newEnc [SoapEncoding create [self]::[my autoname enc]]
    my encodingHandler $newEnc
    set enc $newEnc
  }
   #my log "adding Namespace $prefix:$uri at [self] istype [self class]"
  $enc add $encodingURI
}

SoapElement ad_instproc parseAttributes {node} {

		<p>The task of processing a SOAP element's attributes follows a recurring pattern: First, the list of attributes is filtered for attributes declaring namespaces for the current element's scope. Second, the bundle of attached attributes is checked for element-specific encoding conventions (encodingStyle attribute). Both types of attributes are registered with their specific handlers that are subsequently nested into the element object (see <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapEncoding'>::xosoap::marshaller::SoapEncoding</a> or <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapNamespace'>::xosoap::marshaller::SoapNamespace</a> for more details).</p>

		@author stefan.sobernig@wu-wien.ac.at
		@creation-date November, 2 2005

		@param node A tDOM node object representing the current element subject to parsing.

} {

	#puts [$rootNode attributes *]
    foreach attrib [$node attributes *] {
	# filter namespace declaring attributes and encodingStyle 
	# (see http://groups.yahoo.com/group/tdom/message/317)
	if {[llength $attrib] == 3} {
		#my log "attr1: [lindex $attrib 0], attr2: [lindex $attrib 1], attr3: [lindex $attrib 2]"
	    #puts [$node getAttribute "xmlns:[lindex $attrib 0]"]
	    if {[string equal [lindex $attrib 0] [lindex $attrib 1]] && [string equal [lindex $attrib 2] ""]} {
	    my registerNS [lindex $attrib 0] [$node getAttribute "xmlns:[lindex $attrib 0]"] 
	    } elseif {[string equal [lindex $attrib 0] "encodingStyle"]} {
	    my registerEnc [lindex $attrib 2]
	    } 
	}
    }


}

###############################################
# Soap Syntax Tree
###############################################

::xotcl::Class SoapEnvelope -superclass SoapElement -parameter {encodingStyle nsEnvelopeVersion} -ad_doc {

	<p>The delegate object for the SOAP-ENV:Envelope element. It acts as the top-level or root element of the SOAP syntax/ object tree (see <a href='/xotcl/show-object?object=::xosoap::marshaller::Composite'>::xosoap::marshaller::Composite</a>).</p> 

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005

}

SoapEnvelope ad_instproc parse {rootNode} {

		<p>The parse method of <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapEnvelope'>::xosoap::marshaller::SoapEnvelope</a> provides the fundamentals to create an object representation of the SOAP-ENV XML element and prepares the parsing of the next level of the SOAP syntax tree by identifying and nesting the respective delegate objects, i.e. <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapHeader'>::xosoap::marshaller::SoapHeader</a> and <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapBody'>::xosoap::marshaller::SoapBody</a>. Due to the composite forwarding of parse calls method (see )to each suceeding/ nested object, the respective parsing is enforced after SoapEnvelope's parse terminates by creating the objects to be called next. Therefore, this is referred to as "self-expanding composite".</p> 
		
		@author stefan.sobernig@wu-wien.ac.at
		@creation-date August, 19 2005

		@param rootNode The top most or root element of the SOAP/XML request as tDOM domNode object.
		


} {

    my elementNamespace [$rootNode prefix]
    my elementName [$rootNode localName]
    
    my nsEnvelopeVersion [$rootNode namespaceURI]
	
    # process element's attributes
	
	my parseAttributes $rootNode
    
    # get value of namespace SOAP-ENC
    
    my encodingStyle [[my resolveNSHandler] get "SOAP-ENC"]
    
    foreach child [$rootNode childNodes] {
    
	set cName [$child localName]
	set tmpCommand "Soap$cName [self]::$cName"
	eval $tmpCommand

    }   
}

::xotcl::Class SoapHeader -superclass SoapElement -ad_doc {

	<p>The delegate object for the SOAP-ENV:Header element.</p> 

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005
}

SoapHeader ad_instproc parse {rootNode} {

		<p>The parse method of <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapHeader'>::xosoap::marshaller::SoapHeader</a> provides the fundamentals to create an object representation of the SOAP-ENV:Header XML element</p>


		@author stefan.sobernig@wu-wien.ac.at
		@creation-date August, 19 2005

		@param rootNode The top most or root element of the SOAP/XML request as tDOM domNode object.

} {
    
    
} 

::xotcl::Class SoapHeaderEntry -superclass SoapElement

::xotcl::Class SoapBody -superclass SoapElement -ad_doc {

	<p>The delegate object for the SOAP-ENV:Body element.</p> 

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005
}

SoapBody ad_instproc parse {rootNode} {

	<p>The parse method of <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapBody'>::xosoap::marshaller::SoapBody</a> provides the fundamentals to create an object representation of the SOAP-ENV:Body XML element. As specified for the RPC mode of operation, a single child of type <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapBodyEntry'>::xosoap::marshaller::SoapBodyEntry</a> is nested and parsed subsequently (see <a href='http://www.w3.org/TR/2000/NOTE-SOAP-20000508/#_Toc478383495'>SOAP 1.1</a> and <a href='http://www.w3.org/TR/2003/REC-soap12-part1-20030624/#soapenv'>SOAP 1.2</a> specs).</p>

		@author stefan.sobernig@wu-wien.ac.at
		@creation-date August, 19 2005

		@param rootNode The top most or root element of the SOAP/XML request as tDOM domNode object.
		
		@see <a href='/api-doc/proc-view?proc=::xosoap::marshaller::SoapBodyEntry+instproc+parse'>::xosoap::marshaller::SoapBodyEntry parse</a>


} {

        
    set bodyNode [$rootNode selectNodes /SOAP-ENV:Envelope/SOAP-ENV:Body]
    my elementNamespace [$bodyNode prefix]
    my elementName [$bodyNode localName]
    my parseAttributes $bodyNode
    set child [$bodyNode firstChild]
    SoapBodyEntry [self]::[$child localName]
    
} 

::xotcl::Class SoapBodyEntry -superclass SoapElement -parameter {targetMethod} -ad_doc {

	<p>The delegate object for the single child element of SOAP-ENV:Body as defined for RPC-style SOAP.</p> 

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005
}
SoapBodyEntry ad_instproc init args {} {

    my set methodArgs [list]
    next  

}

SoapBodyEntry ad_instproc parse {rootNode} {

		<p>The parse method of <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapBodyEntry'>::xosoap::marshaller::SoapBodyEntry</a> provides the fundamentals to create an object representation of the SOAP-ENV:Body XML element. It major objective is the extraction of the core invocation info, i.e. the remote method to be invoked and the corresponding method arguments to pass to the method invocation.</p>

		@author stefan.sobernig@wu-wien.ac.at
		@creation-date August, 19 2005

		@param rootNode The top most or root element of the SOAP/XML request as tDOM domNode object.
		

} {
    
    my instvar methodArgs
    
    set bodyNode [$rootNode selectNodes /SOAP-ENV:Envelope/SOAP-ENV:Body]
    
    set meNode [$bodyNode firstChild]

    my elementNamespace [$meNode prefix]
    my elementName [$meNode localName]

    my targetMethod [$meNode localName]
    
    my parseAttributes $meNode
    
    foreach argNode [$meNode childNodes] {
	
	set argName [$argNode nodeName]
	set argValue [$argNode text]
	lappend methodArgs [list $argName $argValue]

    }   
   
} 

::xotcl::Class SoapFault -parameter {exception {soapVersion 1.1}} -ad_doc {

	<p>Provides for generating Soap Fault messages from xoSoap <a href='/xotcl/show-object?object=::xosoap::Exception'>exceptions</a> and for serializing them to plain SOAP/XML.</p> 

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005
}

SoapFault ad_instproc asXML {} {

	<p>It is reponsible for generating a valid Soap Fault tDOM structure, serializing and returning it.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005
	
	@return The final, serialized SOAP Fault as string


} {
    
    
    set soapVersionNS ""
    switch [my soapVersion] {
	1.1	{ set soapVersionNS "http://schemas.xmlsoap.org/soap/envelope/" }
	1.2	{ set soapVersionNS "http://www.w3.org/2003/05/soap-envelope"}
	default { set soapVersionNS "http://schemas.xmlsoap.org/soap/envelope/"}
    }

    set doc [dom createDocument "SOAP-ENV:Envelope"]
    set node [$doc documentElement]
    $node setAttribute "xmlns:SOAP-ENV" $soapVersionNS
    set body [$node appendChild [$doc createElement "SOAP-ENV:Body"]] 
    set fault [$body appendChild [$doc createElement "SOAP-ENV:Fault"]]
    # faultcode
    set faultCode [$fault appendChild [$doc createElement "faultcode"]]
    set faultCodeValue [$faultCode appendFromList [list \#text [[my exception] faultCode]]]
    # faultstring
    set faultString [$fault appendChild [$doc createElement "faultstring"]]
    set faultStringValue [$faultString appendFromList [list \#text [[my exception] errorMessage]]]
    #detail
    set faultDetail [$fault appendChild [$doc createElement "detail"]]
    set faultDetailValue [$faultDetail appendFromList [list \#text [[my exception] asXML]]]
    

    return [$doc asXML]
}
}
