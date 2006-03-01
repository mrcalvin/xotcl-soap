ad_library {
   
    <p>Library providing visitor facilities for crawling composite structures as provided by nesting objects derived from <a href='/xotcl/show-object?object=::xosoap::marshaller::Composite'>::xosoap::marshaller::Composite</a>:</p>
    <p>
    <ul>
    	<li><a href='/xotcl/show-object?object=::xosoap::visitor::AbstractVisitor'>xosoap::visitor::AbstractVisitor</a> provides a generic interface for visitors.</li>
    	<li><a href='/xotcl/show-object?object=::xosoap::visitor::SoapMarshallerVisitor'>xosoap::visitor::SoapMarshallerVisitor</a> serves as marshaller/ serializer of SOAP object trees.</li>
    	<li><a href='/xotcl/show-object?object=::xosoap::visitor::SoapMarshallerVisitor'>xosoap::visitor::SoapMarshallerVisitor</a> serves as demarshaller/ deserializer of SOAP/XML (request) messages.</li>     	   	
    </ul>
    </p>
    

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August 18, 2005
    @cvs-id $Id$

  
}


namespace eval xosoap::visitor {

###############################################
# Visitors:
###############################################

#ns_log notice "::xotcl::Class / Object ad_doc ok? [::xotcl::Class info methods] +++ [::xotcl::Object info methods] "

::xotcl::Class AbstractVisitor -ad_doc {

	<p>An class providing an interface to be implemented by each concrete visitor, in particular the method visit.</p> 

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 20 2005

}
AbstractVisitor abstract instproc visit {host} 

::xotcl::Class SoapMarshallerVisitor -superclass AbstractVisitor -parameter {{xmlDoc ""} {parentNode ""}} -ad_doc {

	<p>This visitor is used to generate a serialized SOAP response message based on the SOAP syntax tree as derived from the initial request and the result of invocation (see also <a href='/api-doc/proc-view?proc=::xosoap::marshaller::Marshaller+instproc+marshal'>xosoap::marshaller::Marshaller marshal</a>).</p> 

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 20 2005

}

SoapMarshallerVisitor ad_instproc visit obj {


	<p>The concrete implementation of the <a href='/api-doc/proc-view?proc=::xosoap::visitor::AbstractVisitor+instproc+visit'>abstract visit method</a> required for each concrete visitor. As the visitor crawls the entire SOAP syntax / object tree, each visited object of type <a href='/xotcl/show-object?object=::xosoap::visitor::SoapElement'>xosoap::visitor::SoapElement</a> is evaluated and mirrored into a node of a tDOM document that can finally be serialized by using asXML procedure provided by tDOM dom objects. First, it is verified whether the current visit is the initial one, i.e. a visit of the root object of the SOAP object tree. If so, a new tDOM document object is created. Then the current object is appended as child node and the namespace handlers for the current scope are resolved. If namespaces are defined at this level, they are appended to the current node as attributes. If the current object is of type <a href='/xotcl/show-object?object=::xosoap::visitor::SoapBodyEntry'>xosoap::visitor::SoapBodyEntry</a>, a final text node representing the invocation result is appended.</p>
	
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 20 2005
	
	@param obj An object of type or derived from <a href='/xotcl/show-object?object=::xosoap::visitor::SoapElement'>xosoap::visitor::SoapElement</a>.
} {
    
    my instvar xmlDoc resultValue

    set node {}

    set elementPrefix [$obj elementNamespace]
    set elementName {}
    if {[$obj istype ::xosoap::marshaller::SoapBodyEntry]} {
	set elementName "[$obj elementName]Response"
    } else {
	set elementName [$obj elementName]
    }

    # create a root node, provided it has not been set yet
    if {[string equal [my parentNode] ""]} {
	set doc [dom createDocument "$elementPrefix:$elementName"]
	set xmlDoc $doc
	set node [$doc documentElement]
	puts "$elementPrefix:$elementName"
    } else {

	set node [[my parentNode] appendChild [$xmlDoc createElement "$elementPrefix:$elementName"]]
	
    }

    # verify whether current node hosts namespace declarations for its sub-tree

    set nsHandler [$obj resolveNSHandler]
    if {[string first $obj $nsHandler] != "-1"} {
	foreach prefix [$nsHandler getPrefixes] {
	    $node setAttribute "xmlns:$prefix" "[$nsHandler get $prefix]"
	}
    }
	
	# verify whether current node contains an encoding style declaration for its scope
	
	set encHandler [$obj resolveEncHandler]
	#my log "[$obj info class]: $encHandler"
    if {[string first $obj $encHandler] != "-1"} { 
	
	$node setAttribute "SOAP-ENV:encodingStyle" [join [$encHandler get]]
	
    }
	
    # if current obj is leaf node -> body entry, introduce the resultValue
    if {[$obj istype ::xosoap::marshaller::SoapBodyResponse]} {
	set resultNode [$node appendChild [$xmlDoc createElement [$obj elementName]]]
	set valueNode [$resultNode appendChild [$xmlDoc createTextNode [$obj responseValue]]]
    }

    # set current node the parent for the next visited sub-node 
    # in the soap syntax tree

    my parentNode $node

    
}

SoapMarshallerVisitor ad_instproc releaseOn {node} {

	<p>A small helper method to initiate a visitor's crawl over an object tree.</p> 

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 20 2005
	
	@param node The top-level or root object of the SOAP syntax / object tree representing the intial request.
	@param resultValue The result as returned by the actual invocation.


} {
  
    #my set resultValue $resultValue
    if {[$node istype ::xosoap::marshaller::SoapElement]} {
	$node accept [self] 
    }

    #puts [[my xmlDoc] asXML]
  
}

##################################

::xotcl::Class SoapRequestVisitor -superclass AbstractVisitor -parameter {serviceMethod serviceArgs} -ad_doc {

	<p>This visitor extracts relevant invocation infos, i.e. name of called remote method and arguments supplied, and stores these in terms of parameters for later access (see also <a href='/api-doc/proc-view?proc=::xosoap::marshaller::Marshaller+instproc+marshal'>xosoap::marshaller::Marshaller demarshal</a>).</p> 

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 20 2005

}

SoapRequestVisitor ad_instproc visit obj {

	<p>This method specifies the visitor's operations on each object visited when crawling an object tree. To be more specific,
	it ignores all objects other than typed <a href='/xotcl/show-object?object=::xosoap::visitor::SoapBodyEntry'>xosoap::visitor::SoapBodyEntry</a>. If a leaf object of this type is reached, it extracts the relevant information.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 20 2005
	
	@param obj An object of type / derived from <a href='/xotcl/show-object?object=::xosoap::visitor::SoapElement'>xosoap::visitor::SoapElement</a>.


} {
	
	my instvar serviceMethod serviceArgs
 
     if {[$obj istype ::xosoap::marshaller::SoapBodyEntry]} {

     set serviceMethod [$obj elementName]
     # provide for correct order of argument array
     
     set tmpArgs ""
     
     foreach keyvalue [$obj set methodArgs]  {	 
		
		#my log "i: [lindex $keyvalue 0], j: [lindex $keyvalue 1]"
		append tmpArgs " " "{[lindex $keyvalue 1]}"     
	  
	  }     
	  
     set serviceArgs $tmpArgs
     
     #my log "$obj: [my serviceMethod] [my serviceArgs]"
     }

}

SoapRequestVisitor ad_instproc releaseOn node {

	<p>A small helper method to initiate a visitor's crawl over an object tree.</p> 

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date August, 20 2005
	
	@param node The top-level or root object of the SOAP syntax / object tree representing the intial request.
	@param resultValue The result as returned by the actual invocation.

} {
    
  
	
	$node accept [self] 
    
    
}

::xotcl::Class SoapResponseVisitor -superclass AbstractVisitor -parameter {batch}

SoapResponseVisitor ad_instproc visit {obj} {} {

	if {[$obj istype ::xosoap::marshaller::SoapBodyEntry]} {
		
		$obj class ::xosoap::marshaller::SoapBodyResponse
		$obj elementName [append [$obj elementName] "Result"]
		$obj responseValue [my batch]
		
    }

}
SoapResponseVisitor ad_instproc releaseOn {node} {} {

	$node accept [self] 

}

}