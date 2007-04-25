ad_library {
  
  Library providing SOAP marshalling / demarshalling facilities
  
  @author stefan.sobernig@wu-wien.ac.at
  @creation-date August 18, 2005
  @cvs-id $Id$
  
}

namespace eval ::xosoap::marshaller {
  
  #######################
  #######################
  # staging
  #######################
  #######################

  namespace import -force ::xorb::aux::*
  namespace import -force ::xosoap::exceptions::*
  namespace import -force ::xorb::datatypes::*


  ::xotcl::Class Soap 
  Soap ad_instproc init {} {} {
    
    my instvar namespaces
    set namespaces(xsd) "http://www.w3.org/2001/XMLSchema"
    set namespaces(xsi) "http://www.w3.org/1999/XMLSchema-instance"
    next
    
  }
  
  ::xotcl::Class Soap1.1 -superclass Soap 
  Soap1.1 ad_instproc init {} {} {
    next
    my instvar namespaces
    set namespaces(soap-env) "http://schemas.xmlsoap.org/soap/envelope/"
    set namespaces(soap-enc) "http://schemas.xmlsoap.org/soap/encoding/"
  }
  
  ::xotcl::Class Soap1.2 -superclass Soap
  Soap1.2 ad_instproc init {} {} {
    next
    my instvar namespaces
    set namespaces(soap-env) "http://www.w3.org/2003/05/soap-envelope"
    set namespaces(soap-enc) "http://www.w3.org/2003/05/soap-encoding" 
  }
  
  #######################
  #######################
  # Class SoapNamespace
  #######################
  #######################

  ::xotcl::Class SoapNamespace -ad_doc {
    <p>An OO representation for namespaces attached to the 
    various elements that a SOAP/XML envelope is made up by.
    Its instances act as namespace handlers with each SOAP 
    element object having assigned a concrete handler. Each handler
    stores an array of prefix-uri pairs that apply to the 
    corresponding SOAP element. Succeeding/ preceeding handlers
    are therefore detectable as within an object tree / composite of 
    <a href='/xotcl/show-object?object=::marshaller::SoapElement'>\
	SoapElements</a> inferring about parent-child relationsships is
    possible. This helps implement the Chain of responsibility pattern 
    for namespace handler and therefore scope for validity of namespaces: 
    As XML namespaces are valid for the current element level and, provided that
    there are no succeeding ones, for the its sub-tree, this allows to 
    construct SOAP responses that inherit these dependencies/ 
    namespace hierarchies from the initial SOAP request 
    (see <a href='/xotcl/show-object?object=::xosoap::visitor::\
	 SoapMarshallerVisitor'>::xosoap::visitor::SoapMarshallerVisitor</a>).
    </p>

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 19 2005

  }
  SoapNamespace ad_instproc init args {} {
    my array set nsArray {}
   }
  SoapNamespace ad_instproc add {prefix uri} {

    <p>
    By calling this method, a new prefix-uri pair can be added
    to the Namespace Handler of the current SOAP element object
    in the overall parsing process.
    </p>
    
    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 19 2005
    
    @param prefix The namespace prefix as identified in the \
	SOAP/XML request, , i.e. a "xmlns"-attribute.
    @param uri The namespace URI as identified in the SOAP/XML \
	request, i.e. a "xmlns"-attribute.
    
    @see <a href='/api-doc/proc-view?proc=::xosoap::marshaller::\
	SoapElement+instproc+registerNS'>::xosoap::marshaller::\
	SoapElement registerNS</a>
  } {
    my set nsArray($prefix) $uri
  }

  SoapNamespace ad_instproc get {prefix} {
    <p>
    Returns the namespace URI corresponding to the key represented
    by the prefix's value.
    </p>
    
    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 19 2005
    
    @param prefix The namespace prefix as identified in
    the SOAP/XML request, , i.e. a "xmlns"-attribute.
  } {

    return [lindex [my array get nsArray $prefix] 1]

  }

  SoapNamespace ad_instproc getPrefixes {} {
    <p>
    Returns all prefixes (keys) currently stored by the
    namespace handler.
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

    <p>The SOAP specs allow for varying encoding 
    conventions to be assigned to an element and its 
    sub-tree scope. Provided that an encodingStyle attribute 
    is specified for an element, resolving the responsible 
    convention for the element under consideration ressembles
    the Chain-of-Responsibility pattern 
    (see also <a href='/xotcl/show-object?object=::xosoap::\
	 marshaller::SoapNamespace'>::xosoap::marshaller::SoapNamespace</a>).
    </p>

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

  
  #######################
  #######################
  # Class (Composite)
  # SoapElement
  #######################
  #######################

  PreOrderTraversal SoapElement -superclass TypedOrderedComposite \
      -parameter {
	elementName
	elementNamespace
	namespaceHandler
	encodingHandler
      } -ad_doc {
   
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 19 2005
      } -instproc init args {
	# / / / / / / / / / / / / / / / / / / 
	# specifies type constraint
	# as required by TypedOrderedComposite
	my type [self class]
      }

  SoapElement addOperations [list parse accept]
  SoapElement abstract instproc parse {rootNode}
  SoapElement ad_instproc accept {visitor} {
    
    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 19 2005
    
  } {
    if {[my istype [self class]]} {
      $visitor visit [self]
    }
  }

  SoapElement ad_instproc resolveNSHandler {} {

    <p><This method helps realise what is referred to as 
    Chain of Responsibility pattern for namespace handlers 
    (see <a href='/xotcl/show-object?object=::xosoap::marshaller::\
	 SoapNamespace'>::xosoap::marshaller::SoapNamespace</a>).
    If a namespace handler is affiliated with the current SoapElement, 
    it is returned. Otherwise, the task to resolve a valid namespace handler 
    is delegated to the parent object of the current SoapElement
    (Note, that we move in a tree of nested objects).
    </p>

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 19 2005
    
    @return Either an object of type <a href='/xotcl/show-object?\
	object=::xosoap::marshaller::SoapNamespace'>::xosoap::\
	marshaller::SoapNamespace</a> or an empty string.

  } {
    if {[my exists namespaceHandler]} {
      return [my set namespaceHandler]
    } else {
      set p [my info parent]
      if {$p != "::xotcl"} {
	return [$p resolveNSHandler]
      } else {
	return ""
      }
    }
  }

  SoapElement ad_instproc registerNS {{prefix_uri {}}} {

    <p>In the course of parsing a specific SoapElement 
    (see e.g. <a href='/api-doc/proc-view?proc=::xosoap::marshaller\
	 ::SoapEnvelope+instproc+parse'>::xosoap::marshaller::\
	 SoapEnvelope parse</a>) this method is called
    to <a href='/api-doc/proc-view?proc=::xosoap::marshaller::\
	SoapElement+instproc+resolveNS'>resolve</a> the namespace 
	handler valid in the scope of the current SoapElement. 
	If there is no superordinated namespace handler, a new instance of 
    <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapNamespace'>\
	::xosoap::marshaller::SoapNamespace</a> is nested into the current 
    SoapElement object and returned as the namespace handler responsible for 
    <a href='/api-doc/proc-view?proc=::xosoap::marshaller::SoapNamespace\
	+instproc+add'>adding</a> the prefix-uri pair.</p>

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 19 2005

    @param prefix The namespace prefix as identified in the \
	SOAP/XML request, , i.e. a "xmlns"-attribute.
    @param uri The namespace URI as identified in the \
	SOAP/XML request, i.e. a "xmlns"-attribute.

  } {
    if {$prefix_uri ne {}} {
      set ns [my resolveNSHandler]
      if {[string first [self] $ns] == -1} {
	set newNS [SoapNamespace create [self]::[my autoname ns]]
	my namespaceHandler $newNS
	set ns $newNS
      }
      set l [split $prefix_uri]
      if {[llength $l] ne "2"} {
	error [::xosoap::exceptions::Server::MalformedNamespaceDeclaration new \
		   [subst {
		     '$prefix_uri' could not be transformed 
		     into a list of 2 elements
		   }]]
      }
      $ns add [lindex $l 0] [lindex $l 1]
    }
  }

  SoapElement ad_instproc resolveEncHandler {} {

    <p>It identifies the responsible encoding handler \
	for the current <a href='/xotcl/show-object?object=\
	::xosoap::marshaller::SoapElement'>::xosoap::marshaller\
	::SoapElement</a> in a Chain of Responsibility 
    (see <a href='/xotcl/show-object?object=::xosoap::marshaller\
	 ::SoapNamespace'>::xosoap::marshaller::SoapNamespace</a> 
     for further details).</p>

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date November, 2 2005
    
    @return Either an object of type \
	<a href='/xotcl/show-object?object=::xosoap::marshaller::\
	SoapEncoding'>::xosoap::marshaller::SoapEncoding</a> or an empty string.

  } {
    
    if {[my exists encodingHandler]} {
      return [my set encodingHandler]
    } else {
      set p [my info parent]
      if {$p != "::xotcl"} {
	return [$p resolveEncHandler]
      } else {
	return ""
      }
    }
  }

  SoapElement ad_instproc registerEnc {{encodingURI {}}} {

    <p>It provides for registering a encoding convention URI, 
    as stored in the encodingStyle attribute, with a the encoding 
    handler responsible for the current element.</p>

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date November, 2 2005

    @param encodingURI An URI string pointing to an encoding convention.

  } {
    if {$encodingURI ne {}} {
      set enc [my resolveEncHandler]
      if {[string first [self] $enc] == -1} {
	set newEnc [SoapEncoding create [self]::[my autoname enc]]
	my encodingHandler $newEnc
	set enc $newEnc
      }
      $enc add $encodingURI
    }
  }

  SoapElement ad_instproc parseAttributes {node} {

    <p>The task of processing a SOAP element's attributes follows 
    a recurring pattern: First, the list of attributes is filtered 
    for attributes declaring namespaces for the current element's scope. 
    Second, the bundle of attached attributes is checked for element-specific 
    encoding conventions (encodingStyle attribute). Both types of attributes 
    are registered with their specific handlers that are subsequently nested
    into the element object 
    (see <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapEncoding\
	 '>::xosoap::marshaller::SoapEncoding</a> or 
     <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapNamespace\
	 '>::xosoap::marshaller::SoapNamespace</a> for more details).
    </p>

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date November, 2 2005

    @param node A tDOM node object representing the current element \
	subject to parsing.
  } {

    foreach attrib [$node attributes *] {
      # filter namespace declaring attributes and encodingStyle 
      # (see http://groups.yahoo.com/group/tdom/message/317)
      if {[llength $attrib] == 3} {
	if {[string equal [lindex $attrib 0] [lindex $attrib 1]] && \
		[string equal [lindex $attrib 2] ""]} {
	  my registerNS [list [lindex $attrib 0] \
			     [$node getAttribute "xmlns:[lindex $attrib 0]"]]
	} elseif {[string equal [lindex $attrib 0] "encodingStyle"]} {
	  my registerEnc [lindex $attrib 2]
	} 
      }
    }
  }


  ###############################################
  # Soap Syntax Tree
  ###############################################



  ::xotcl::Class SoapEnvelope -superclass SoapElement -slots {
    Attribute encodingStyle
    Attribute nsEnvelopeVersion
  } -ad_doc {

    <p>The delegate object for the SOAP-ENV:Envelope element. 
    It acts as the top-level or root element of the SOAP syntax/ 
    object tree (see <a href='/xotcl/show-object?object=::xosoap::\
		     marshaller::Composite'>::xosoap::marshaller::\
		     Composite</a>).</p> 

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 19 2005

  }

  SoapEnvelope ad_instproc init {} {} {

    my elementName "Envelope"
    my elementNamespace "SOAP-ENV"
    my registerNS [list "SOAP-ENV" "http://schemas.xmlsoap.org/soap/envelope/"]
    my registerNS [list "SOAP-ENC" "http://schemas.xmlsoap.org/soap/encoding/"]
    my registerNS [list "xsi" "http://www.w3.org/2001/XMLSchema-instance"]
    my registerEnc "http://schemas.xmlsoap.org/soap/encoding/"
  }

  SoapEnvelope proc new {
			 {-registerNS {}}
			 {-registerEnc {}}
			 -response:switch 
			 -header:switch 
			 {-nest {}}
			 args
		       } {
    set head [list]
    if {$header} {
      set head [list ::xosoap::marshaller::SoapHeader new]
    }
    if {$nest ne {}} {
      set injection $nest
    } else {
      if {$response} {
	set injection [list ::xosoap::marshaller::SoapBodyResponse new]
      } else {
	set injection [list ::xosoap::marshaller::SoapBodyRequest new]
      }
    }
   
    set cmd [subst {
      -contains { 
	$head
	::xosoap::marshaller::SoapBody new -contains \
	    [list $injection]
      }
    }]
    my log cmd=$cmd
    #my log ns=$registerNS
    return [eval next $cmd \
		[list -registerNS $registerNS] \
		[list -registerEnc $registerEnc]]	
  }

  SoapEnvelope ad_instproc parse {rootNode} {

    <p>The parse method of 
    <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapEnvelope'>\
	::xosoap::marshaller::SoapEnvelope</a> provides the fundamentals to
    create an object representation of the SOAP-ENV XML element and prepares 
    the parsing of the next level of the SOAP syntax tree by identifying and 
    nesting the respective delegate objects, i.e. <a href='/xotcl/show-object?\
	object=::xosoap::marshaller::SoapHeader'>::xosoap::marshaller::\
	SoapHeader</a> and <a href='/xotcl/show-object?object=::xosoap::\
	marshaller::SoapBody'>::xosoap::marshaller::SoapBody</a>. Due to 
    the composite forwarding of parse calls method (see )to each suceeding/ 
    nested object, the respective parsing is enforced after SoapEnvelope's 
    parse terminates by creating the objects to be called next. Therefore,
    this is referred to as "self-expanding composite".</p> 
    
    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 19 2005

    @param rootNode The top most or root element of the SOAP/XML \
	request as tDOM domNode object.
 } {
    my elementNamespace [$rootNode prefix]
    my elementName [$rootNode localName]
    
    my nsEnvelopeVersion [$rootNode namespaceURI]
    
    # process element's attributes
    
    my parseAttributes $rootNode
    
    # get value of namespace SOAP-ENC
    
    my encodingStyle [[my resolveNSHandler] get "SOAP-ENC"]
 }

  ::xotcl::Class SoapHeader -superclass SoapElement -ad_doc {

    <p>The delegate object for the SOAP-ENV:Header element.</p> 

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 19 2005
  }

  SoapHeader ad_instproc init {} {} {
    my elementName "Header"
    my elementNamespace "SOAP-ENV"
  }

  SoapHeader ad_instproc parse {rootNode} {

    <p>The parse method of 
    <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapHeader'>\
	::xosoap::marshaller::SoapHeader</a> provides the fundamentals
    to create an object representation of the SOAP-ENV:Header XML element</p>

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 19 2005

    @param rootNode The top most or root element of the \
	SOAP/XML request as tDOM domNode object.
  } {} 

  ::xotcl::Class SoapHeaderEntry -superclass SoapElement

  ::xotcl::Class SoapBody -superclass SoapElement -ad_doc {

    <p>The delegate object for the SOAP-ENV:Body element.</p> 

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 19 2005
  }

  SoapBody ad_instproc init {} {} {

    my elementNamespace "SOAP-ENV"
    my elementName "Body"
  }

  SoapBody ad_instproc parse {rootNode} {

    <p>The parse method of 
    <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapBody'>\
	::xosoap::marshaller::SoapBody</a> provides the fundamentals to 
    create an object representation of the SOAP-ENV:Body XML element. 
As specified for the RPC mode of operation, a single child of type 
<a href='/xotcl/show-object?object=::xosoap::marshaller::SoapBodyEntry'>\
	::xosoap::marshaller::SoapBodyEntry</a> is nested and parsed 
    subsequently (see <a href='http://www.w3.org/TR/2000/NOTE-SOAP-20000508\
		      /#_Toc478383495'>SOAP 1.1</a> and 
		  <a href='http://www.w3.org/TR/2003/REC-soap12-part1-20030624\
		      /#soapenv'>SOAP 1.2</a> specs).</p>

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 19 2005

    @param rootNode The top most or root element of the SOAP/XML \
	request as tDOM domNode object.
    
    @see <a href='/api-doc/proc-view?proc=::xosoap::marshaller::\
	SoapBodyEntry+instproc+parse'>::xosoap::marshaller::SoapBodyEntry parse</a>
  } {
    set bodyNode [$rootNode getElementsByTagName *Body]
    my elementNamespace [$bodyNode prefix]
    my elementName [$bodyNode localName]
    my parseAttributes $bodyNode
  } 

  ::xotcl::Class SoapBodyEntry -superclass SoapElement -slots {
    Attribute targetMethod
  } -ad_doc {
    <p>The delegate object for the single child element of 
    SOAP-ENV:Body as defined for RPC-style SOAP.</p> 
    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 19 2005
  }
  SoapBodyEntry ad_instproc init args {} {
    my elementNamespace "m"
    my registerNS [list "m" "Some-URI"]
    my set methodArgs [list]
    next  
  }


  # # # # # # # # # # # # #
  # # # # # # # # # # # # #
  # # Class: SoapFault 
  # # # # # # # # # # # # #
  # # # # # # # # # # # # #

  ::xotcl::Class SoapFault -superclass SoapBodyEntry -slots {
    Attribute faultcode
    Attribute faultstring
    Attribute detail
  }
  SoapFault instproc init args {
    my elementName "Fault"
    my elementNamespace "SOAP-ENV"
    my registerNS {xosoap urn:xotcl-soap}
  }

  # # # # # # # # # # # # #
  # # # # # # # # # # # # #
  # # Class: SoapBodyResponse 
  # # # # # # # # # # # # #
  # # # # # # # # # # # # #


  ::xotcl::Class SoapBodyResponse -slots {
    Attribute responseValue -default {}
  } -superclass SoapBodyEntry
  
  SoapBodyResponse ad_instproc parse {rootNode} {} {
    my instvar responseValue
    set bodyNode [$rootNode getElementsByTagName *Body]
    set responseNode [$bodyNode firstChild]
    set returnNode [$responseNode firstChild]
    
    #     set r {}
    #     if {$returnNode ne {}} {
    #       if {[$returnNode nodeType] eq "TEXT_NODE"} {
    # 	set r [$returnNode nodeValue]
    #       } elseif {[$returnNode nodeType] eq "ELEMENT_NODE"} {
    # 	set r [$returnNode text]
    #       }
    #     }

    # / / / / / / / / / / / /
    # introducing anythings!
    set any [::xorb::datatypes::Anything new -isRoot true -parse $responseNode]
    set responseValue $any
  }

  # # # # # # # # # # # # #
  # # # # # # # # # # # # #
  # # Class: SoapBodyRequest 
  # # # # # # # # # # # # #
  # # # # # # # # # # # # #

  ::xotcl::Class SoapBodyRequest -slots {
    Attribute remoteMethod
    Attribute remoteArgs
  } -superclass SoapBodyEntry 

  SoapBodyRequest ad_instproc parse {rootNode} {

    <p>The parse method of <a href='/xotcl/show-object?object=\
	::xosoap::marshaller::SoapBodyEntry'>::xosoap::marshaller::\
	SoapBodyEntry</a> provides the fundamentals to create an
	object representation of the SOAP-ENV:Body XML element.
	It major objective is the extraction of the core invocation 
	info, i.e. the remote method to be invoked and the corresponding
	method arguments to pass to the method invocation.
    </p>

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 19 2005

    @param rootNode The top most or root element of the SOAP/XML \
	request as tDOM domNode object.
  } {
    my instvar methodArgs
    set bodyNode [$rootNode getElementsByTagName *Body]
    set meNode [$bodyNode firstChild]
    my elementNamespace [$meNode prefix]
    my elementName [$meNode localName]
    my targetMethod [$meNode localName]
    my parseAttributes $meNode
    
    foreach argNode [$meNode childNodes] {
      # / / / / / / / / / / / / / / / / /
      # Introducing 'anythings' as generic
      # type containers/ handlers
      set any [Anything new -parse $argNode -name [$argNode nodeName]]
      lappend methodArgs $any
    }
  } 


  # # # # # # # # # # # # 
  # # # # # # # # # # # # 
  # # Class SoapParameter
  # # # # # # # # # # # # 
  # # # # # # # # # # # # 
  
  ::xotcl::Class SoapParameter -slots {
    Attribute domNode
    Attribute value -type ::xosoap::xsd::Type
    Attribute name
  }

  SoapParameter instproc getObject {-forNode:required} {
    my instvar objectsForNodes
    if {[array exists objectsForNodes] && \
	    [info exists objectsForNodes($forNode)]} {
      return $objectsForNodes($forNode)
    }
  }

  SoapParameter instproc setObject {-forNode:required obj} {
    my instvar objectsForNodes
    set objectsForNodes($forNode) $obj
  }

  SoapParameter instproc init {} {
    # / / / / / / / / / / / / / / / / / / /
    # type of parameter: atom or compound?
    if {[my exists domNode]} {
       my instvar domNode
      my setObject -forNode $domNode [self]
      set childNodeType [[$domNode firstChild] nodeType]
      if {$childNodeType == "TEXT_NODE"} {
	my parseAtom
      } else {
	my parseCompound
      }
    }
  }
  
  SoapParameter instproc isElementWise {node} {
    Soap1.1 instvar namespaces
    return [string equal -nocase \
		[$node namespaceURI] \
		$namespaces(soap-enc)]
  }

  SoapParameter instproc isTypeWise {node} {
    Soap1.1 instvar namespaces
    return [expr {$node hasAttributeNS $namespaces(xsi) "type"}]
  }
  
  SoapParameter instproc isByPrecedence {node} {
    my instvar parent
    Soap1.1 instvar namespaces
    if {[$parent type] eq "::xosoap::xsd::Array" && \
	    [$parent type] ne "ur-type"} {
      return 1
    } else {
      return 0
    }
  }

  SoapParameter instproc parseAtom {} {
    my instvar domNode parent value
    Soap1.1 instvar namespaces
    # / / / / / / / / / / / / / / /
    # Atom (primitive) types come in
    # two (three) encoding flavours:
    # 1) element-wise (SOAP-specific) 
    # encoding (e.g. SOAP-ENC:String, ...)
    # 2) type-wise (XS-specific)
    # encoding (e.g. <... type="xsd:string" .../>,)
    # 2a) specific to XS atomic types is that
    # they can be typed by means of precedence,
    # i.e. if contained/ member of an Array compound
    # type, they (if not specific about their type)
    # inherit the type of the Array parent compound.
    # 3) custom encoding schemes, specified
    # by XS specifications (NOT IMPLEMENTED)
    set atomType "default"
    if {[my isElementWise $domNode]} {
      # we have 1)
      set attribute [$domNode getAttributeNS $namespaces(xsi) "type"]
      set atomType [lindex [split $attribute ":"] 1]
    } elseif {[my isTypeWise $domNode]} {
      # we have 2)
      
    } elseif {[my isByPrecedence $domNode]} {
      set atomType [$parent type]
    } else {
      # we have 3) -> exception
      if {[my isByPrecedence $domNode]} {
	set atomType [$parent type]
      } else {
	error [::xosoap::exceptions::InvalidSoapEncodingException new \
		   "Causing soap parameter: [$domNode asXML]"]
      }
    }

    set typeObj $xsd($atomType)
    set parent [my getObject -forNode [$domNode parentNode]]
    if {$parent eq [self]} {
      set value [$typeObj new -value [$domNode text]]
    } else {
      my add -parent $parent \
	  -child [list $typeObj new -value [$domNode text]] \
	  -node $domNode
      $parent slots 
    }
    
  }

  SoapParameter instproc add {
    -parent
    -child
    -node
  } {
    $parent mixin [self class]::ComplexType
    $parent node $node
    $parent param [self]
    $parent slots $child
    $parent mixin delete [self class]::ComplexType
  }

  Class SoapParameter::ComplexType -slots {
    Attribute node
    Attribute param
  }
  SoapParameter::ComplexType instproc notify {name} {
    my instvar node param
    $param setObject -forNode $node [self]::slot::$name
    next
  }

  SoapParameter instproc parseCompound {} {
    
  }
  
  # # # # # # # # # 
  # # # # # # # # #
  # unstaging
  # # # # # # # # #
  # # # # # # # # #
  
  namespace export SoapElement SoapEnvelope SoapHeader SoapBody \
      SoapBodyEntry SoapBodyResponse SoapBodyRequest SoapFault \
      SoapParameter

  ::xotcl::Class Argument -parameter {domNode} 
  Argument set mapping(default) ::xorb::aux::String
  Argument set mapping(int) ::xorb::aux::Integer 
  Argument set mapping(string) ::xorb::aux::String 
  Argument set mapping(double) ::xorb::aux::Double 
  Argument set mapping(boolean) ::xorb::aux::Boolean 
  Argument set mapping(struct) ::xorb::aux::Dict 
  Argument set mapping(array) ::xorb::aux::Array 
  

  Argument ad_instproc init args {} {
    
    my set current [self]
    my parse
  }	
  

  Argument ad_instproc parse {} {} {
    
    
    if {[my exists domNode]} {
      
      my instvar domNode
      
      set childNodeType [[$domNode firstChild] nodeType]
      if {$childNodeType == "TEXT_NODE"} {
	my parseAtom
      } else {
	my parseCompound
      }
    }

  }

  Argument ad_instproc parseAtom {} {} {
    
    my instvar domNode current
    [self class] instvar mapping
    [1.1 new -volatile] instvar namespaces
    
    

    
    set typeIdentifier "default"

    if {[string equal -nocase [$domNode namespaceURI] $namespaces(soap-enc)]} {
      
      set typeIdentifier [string tolower [$domNode localName] 0 0]
      
      # follows XML schema type-wise encoding of data types
    } elseif {[$domNode hasAttributeNS $namespaces(xsi) "type"]} {
      set typeIdentifier [lindex [split [$domNode getAttributeNS $namespaces(xsi) "type"] ":"] 1]
      if {[$current istype ::xorb::aux::Array] && [$current type] ne "ur-type" && $typeIdentifier ne [$current type]} {
	my error "Typing of atom '[$domNode nodeName]' violates type limitation by Array declaration ([$current type])."
      }
    } elseif {[$current istype ::xorb::aux::Array] } {
      if {[$current type] ne "ur-type"} {
	set typeIdentifier [$current type]
      } else {
	
	my error "Atom is not typed by any means, neither attribute- /element-wise nor by precedence."
	
      }
      
      
    }
    
    #my log "atom identifier: $typeIdentifier"
    
    set container [$mapping($typeIdentifier)]
    $container new -childof $current -name [$domNode nodeName] -detainee [$domNode text]
    
    # register atom with the superlevel compound
    #if {$current != [self]} {
    
    #	my log "current($current): [$current info class], containerInst ($containerInst): [$containerInst info class]"
    
    #	$current ascribe $containerInst 
    #}
    
  }

  Argument ad_instproc parseCompound {} {} {

    
    my instvar domNode current
    [self class] instvar mapping
    [1.1 new -volatile] instvar namespaces
    # struct, array?
    
    my log "attr=[$domNode hasAttributeNS $namespaces(soap-enc) "arrayType"]"
    
    if {([$domNode namespaceURI] eq $namespaces(soap-enc) && [string equal -nocase [$domNode localName] "Array"]) || [$domNode hasAttributeNS $namespaces(soap-enc) "arrayType"] || ([$domNode hasAttributeNS $namespaces(xsi) "type"] && [string equal -nocase [$domNode getAttributeNS $namespaces(xsi) "type"] "SOAP-ENC:Array"])} {
      set typeIdentifier "array"
      set container $mapping($typeIdentifier)
      set current [$container new -childof $current -name [$domNode localName] -domNode $domNode]
      if {[$domNode hasAttributeNS $namespaces(soap-enc) "arrayType"]} {
	
	set arrayDeclaration [$domNode getAttributeNS $namespaces(soap-enc) "arrayType"]
	set declv [split $arrayDeclaration ":"]
	#regexp -- {^([a-z,A-Z,[.-.]]*)[[.[.]]([0-9]+)[[.].]]$} $a -> t o
	if {![regexp -- {^([a-z,A-Z,[.-.]]*)[[.[.]]([0-9]+)[[.].]]$} [lindex $declv 1] -> t o]} {
	  my error "Argument parsing: invalid Array declaration."
	}
	
	$current type $t
	$current occurrence $o 
	
      }
    } else {
      
      set typeIdentifier "struct"
      set container [$mapping($typeIdentifier)]
      set current [$container new -childof $current -name [$domNode localName] -domNode $domNode]
    }
    
    my log "typeIdentifier: $typeIdentifier, class: [$current info class]"
    
    foreach itemNode [$domNode childNodes] {
      my domNode $itemNode
      my parse
    }
    
  }

  Argument ad_instproc rollOut {} {} {
    
    #my log "argument container: [lindex [my info children] 0], type: [[lindex [my info children] 0] info class]"
    
    if {[my info children] != ""} {
      
      my log "childs: [my info children]"
      return [[lindex [my info children] 0] getValue]
    } 
  }

}
