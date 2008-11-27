::xo::library doc {
  
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
  #namespace import -force ::xosoap::xsd::*
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

  } -parameter {
    successor ""
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

  SoapNamespace instproc resolvePrefixForUri {uri} {
    # / / / / / / / / / / / / / / /
    # first, resolve URI in
    # the scope of the local
    # namespace handler
    foreach prefix [my array names nsArray] {
      if {[string match [my set nsArray($prefix)] $uri]} {
        return $prefix
      }
    }
    # / / / / / / / / / / / / / /
    # cannot be resolved locally,
    # forward to successor
    my instvar successor
    if {$successor ne {}} {
      return [$successor resolvePrefixForUri $uri]
    } else {
      return ""
    }
  }

  SoapNamespace instproc resolveUriForPrefix {prefix} {
    # / / / / / / / / / / / / / / /
    # first, resolve prefix in
    # the scope of the local
    # namespace handler
    if {[my exists nsArray($prefix)]} {
      return [my set nsArray($prefix)]
    }
    # / / / / / / / / / / / / / /
    # cannot be resolved locally,
    # forward to successor
    my instvar successor
    if {$successor ne {}} {
      return [$successor resolveUriForPrefix $uri]
    } else {
      return ""
    }
  }

  SoapNamespace instproc getFirstHandlerInChain {} {
    my instvar successor
    if {$successor eq ""} {
      # -- i'am the first chain element ...
      return [self]
    } else {
      # -- proceed ...
      return [$successor getFirstHandlerInChain]
    }
  }

  SoapNamespace instproc delete {prefix} {
    my instvar nsArray 
    if {[info exists nsArray($prefix)]} {
      unset nsArray($prefix) 
    }
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
  SoapElement instproc parse {rootNode} {;}
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

#   SoapElement ad_instproc registerNS {{prefix_uri {}}} {

#     <p>In the course of parsing a specific SoapElement 
#     (see e.g. <a href='/api-doc/proc-view?proc=::xosoap::marshaller\
# 	 ::SoapEnvelope+instproc+parse'>::xosoap::marshaller::\
# 	 SoapEnvelope parse</a>) this method is called
#     to <a href='/api-doc/proc-view?proc=::xosoap::marshaller::\
# 	SoapElement+instproc+resolveNS'>resolve</a> the namespace 
# 	handler valid in the scope of the current SoapElement. 
# 	If there is no superordinated namespace handler, a new instance of 
#     <a href='/xotcl/show-object?object=::xosoap::marshaller::SoapNamespace'>\
# 	::xosoap::marshaller::SoapNamespace</a> is nested into the current 
#     SoapElement object and returned as the namespace handler responsible for 
#     <a href='/api-doc/proc-view?proc=::xosoap::marshaller::SoapNamespace\
# 	+instproc+add'>adding</a> the prefix-uri pair.</p>

#     @author stefan.sobernig@wu-wien.ac.at
#     @creation-date August, 19 2005

#     @param prefix The namespace prefix as identified in the \
# 	SOAP/XML request, , i.e. a "xmlns"-attribute.
#     @param uri The namespace URI as identified in the \
# 	SOAP/XML request, i.e. a "xmlns"-attribute.

#   } {
#     if {$prefix_uri ne {}} {
#       set ns [my resolveNSHandler]
#       if {[string first [self] $ns] == -1} {
# 	set newNS [SoapNamespace create [self]::[my autoname ns]]
# 	$newNs successor $ns
# 	my namespaceHandler $newNS
# 	set ns $newNS
#       }
#       set l [split $prefix_uri]
#       if {[llength $l] ne "2"} {
# 	error [::xosoap::exceptions::Server::MalformedNamespaceDeclaration new \
# 		   [subst {
# 		     '$prefix_uri' could not be transformed 
# 		     into a list of 2 elements
# 		   }]]
#       }
#       eval $ns add [lindex $l 0] [lindex $l 1]
#     }
#   }

  SoapElement instproc registerNamespaces {declarations} {
    foreach declaration $declarations {
      switch [llength $declaration] {
	1 { 
	  # -- no custom prefix
	  my registerNS [list $declaration]
	}
	2 {
	  # -- custom prefix
	  my registerNS $declaration
	}
	default {
	  error [subst {
	    Invalid number of elements in namespace declaration: 
	    '$declaration'
	    }]
	}
      }
    }
  }

  SoapElement ad_instproc registerNS {prefix_uri} {

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date Nov, 1 2007

    @param prefix The namespace prefix as identified in the \
	SOAP/XML request, , i.e. a "xmlns"-attribute.
    @param uri The namespace URI as identified in the \
	SOAP/XML request, i.e. a "xmlns"-attribute.

  } {

    if {$prefix_uri ne {}} {
      set ns [my resolveNSHandler]
      if {[string first [self] $ns] == -1} {
	set newNS [SoapNamespace create [self]::[my autoname nsHandler]]
	$newNS successor $ns
	my namespaceHandler $newNS
	set ns $newNS
      }
      switch -- [llength $prefix_uri] {
	1 {set tokens uri}
	2 {set tokens [list prefix uri]}
	default {
	  error [::xosoap::exceptions::Server::MalformedNamespaceDeclaration new \
		     [subst {
		       Invalid namespace declaration '$prefix_uri'.
		     }]]
	}
      }
      foreach $tokens $prefix_uri break;
      if {![info exists prefix]} {
	set documentWideHandler [$ns getFirstHandlerInChain]
	set prefix [$documentWideHandler autoname ns]
      }
      $ns add $prefix $uri
      return $prefix
    }
  }

  SoapElement instproc addAt {object index} {
    my instvar __children
    set __children [linsert $__children $index $object]
    $object set __parent [self]
  }

  SoapElement instproc bindNS {
    uri
    {prefix ""}
  } {
    set nsHandler [my resolveNSHandler]
    set p [$nsHandler resolvePrefixForUri $uri]
    if {$p eq {}} {
      if {$prefix eq {}} {
	set p [my registerNS [list $uri]]
      } else {
	set p [my registerNS [list $prefix $uri]]
      }
    }
    my debug BINDNS=$p
    my elementNamespace $p
  }

  SoapElement instproc resolveNS {{prefix ""}} {
    if {$prefix eq {}} {
      set prefix [my elementNamespace]
    }
    set nsHandler [my resolveNSHandler]
    return [$nsHandler resolveUriForPrefix $prefix]
  }


  SoapElement instproc unregisterNS {prefix} {
    if {$prefix ne {}} {
      set ns [my resolveNSHandler]
      $ns delete $prefix
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
	 # my registerNS -prefix [lindex $attrib 0] \
	  #    -uri [$node getAttribute "xmlns:[lindex $attrib 0]"]
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
  }

  SoapEnvelope proc new {
    {-registerNS {}}
    {-registerEnc {}}
    {-response false}
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
    my debug cmd=$cmd
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

   # / / / / / / / / / / / / / /
   # Verify whether a Soap Header
   # is present and, in case, 
   # add an object representative
   # to take over the parsing
   set headerNode [$rootNode getElementsByTagName *Header]
   #my debug headerNode=$headerNode,firstChild=[$rootNode firstChild]
   if {$headerNode ne {} && $headerNode eq [$rootNode firstChild]} {
     my add [SoapHeader new -childof [self]]
   }
   
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
  } {
    my instvar methodArgs
    set headerNode [$rootNode getElementsByTagName *Header]
    my elementNamespace [$headerNode prefix]
    my elementName [$headerNode localName]
    my parseAttributes $headerNode
    
    set fields [list]
    foreach fieldNode [$headerNode childNodes] {
      set any [::xosoap::xsd::XsAnything new \
		   -name__ [$fieldNode localName] \
		   -parse $fieldNode]

      append fields [subst {
	::xosoap::marshaller::SoapHeaderField new\
	    -elementName [$fieldNode localName] \
	    -value $any \
	    -elementNamespace [$fieldNode prefix] \
	    -parseAttributes $fieldNode
      }]
    }
    if {$fields ne {}} {
      my contains $fields
    }
  } 

  # / / / / / / / / / / / / /
  # Class SoapHeaderField
  # - - - - - - - - - - - - - 

  ::xotcl::Class SoapHeaderField -slots {
    Attribute value -type ::xorb::datatypes::Anything
  } -superclass SoapElement
  
  # / / / / / / / / / / / / / / / / / / / /
  # Soap header fields, or, as officially
  # called in Soap 1.1/1.2 specs, "header blocks",
  # may contain arbitrarily complex elements. We, 
  # therefore, extend basic Anything support
  
  SoapHeaderField instproc setValue {in invocationContext} {
    my instvar value elementName    
    if {![my isobject $in]} {
      #set reader [::xorb::datatypes::AnyReader new \
	#	      -typecode ::xosoap::xsd::XsString \
	#	      -protocol ::xosoap::Soap]
      #my debug READER=[$reader serialize]
      #set any [$reader any]
      set any ::xosoap::xsd::XsString
      set value [$any new \
		     -childof [self] \
		     -name__ $elementName \
		     -set __value__ $in]
    } else {
      my log "WARNING: Compound header types not supported."
    }
  }

  # / / / / / / / / / / / / / / / / / / / /
  # Soap 1.1/1.2 require so-called
  # "SOAP header blocks" to be
  # streamed in a fully-qualified
  # manner. We, therefore, need
  # to:
  # a) register a namespace uri, by
  # referring to either an tcl-to-xml
  # namespace mapping or the impicit
  # tcl-to-urn mapping: We, currently,
  # apply the following resolution order:
  # -1- namespace mapping in invocation
  # context?
  # -2- tcl namespace of client proxy or
  # invocation context obj -> generate
  # urn ...
  # -3- if toplevel (::) or exception (::template) 
  # > xosoap default ...
  # b) binding the element to this
  # namespace ...
  
  SoapHeaderField instproc resolveNamespace {value invocationContext} {
    set tclNamespace [namespace qualifiers $value]
    # TODO: exemptions should be dealt with more
    # generically
    # -3- defaulting? 
    if {$tclNamespace eq "" || \
	    [lsearch -exact [list ::template] ::template] != -1} {
      # xosoap default > parameter?
      return urn:xosoap
    }
    # -1- explicit mapping?
    set xmlNamespace [$invocationContext mapNamespace $tclNamespace]
    return $xmlNamespace
  }

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
    #my registerNS -prefix "m" -uri "Some-URI"]
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
    #my registerNS -prefix xosoap -uri urn:xotcl-soap
  }
  SoapFault instproc parse {rootNode} {
    # / / / / / / / / / / / / / / / / / /
    # We changed, for the very moment,
    # the DOM selector to *:Fault. This is,
    # however, inherently unsafe, namespace
    # awareness needs to be introduced,
    # otherwise multiple nodes form the
    # result set!
    set fault [$rootNode getElementsByTagName *:Fault]
    my elementNamespace [$fault prefix]
    my parseAttributes $fault
    foreach s [[self class] info slots] {
      set a [namespace tail $s]
      set node [$rootNode getElementsByTagName *$a]
      if {$node ne {}} {
	my $a [$node text]
      }
    }
  }
  SoapFault instproc show {} {
    my instvar faultcode faultstring detail
    set r {}
    foreach v [info vars] {
      append r [subst {
	$v: [set $v]
     }]
    }
    return $r
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
    set any [::xosoap::xsd::XsAnything new \
		 -childof [self] \
		 -isRoot__ true \
		 -parse $responseNode]
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
    #
    # NOTE: We need to be pre-cautious with
    # unqualified, local elements (as it is
    # allowed in non-WSI-compliant RPC style)
    # 
    my elementName \
	[expr {[my elementNamespace] eq ""?\
		   [$meNode nodeName]:[$meNode localName]}]
    my targetMethod [my elementName]
    my parseAttributes $meNode
    
    foreach argNode [$meNode childNodes] {
      # / / / / / / / / / / / / / / / / /
      # Introducing 'anythings' as generic
      # type containers/ handlers
      set en [::xosoap::xsd::XsAnything getElementName $argNode]
      set any [::xosoap::xsd::XsAnything new \
		   -name__  $en \
		   -parse $argNode]
      lappend methodArgs $any
    }
  } 
  
  # # # # # # # # # 
  # # # # # # # # #
  # unstaging
  # # # # # # # # #
  # # # # # # # # #
  
  namespace export SoapElement SoapEnvelope SoapHeader SoapBody \
      SoapBodyEntry SoapBodyResponse SoapBodyRequest SoapFault \
      SoapParameter SoapHeaderField
}
