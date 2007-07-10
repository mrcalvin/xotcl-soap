ad_library {
  
  <p>Library providing visitor facilities for crawling composite 
  structures as provided by nesting objects derived from 
  <a href='/xotcl/show-object?object=::xosoap::marshaller::Composite'>\
      ::xosoap::marshaller::Composite</a>:</p>
  <p>
  <ul>
  <li>
  <a href='/xotcl/show-object?object=::xosoap::visitor::\
      AbstractVisitor'>xosoap::visitor::AbstractVisitor</a> provides
  a generic interface for visitors.</li>
  <li>
  <a href='/xotcl/show-object?object=::xosoap::visitor::\
      SoapMarshallerVisitor'>xosoap::visitor::SoapMarshallerVisitor</a> 
  serves as marshaller/ serializer of SOAP object trees.
  </li>
  <li>
  <a href='/xotcl/show-object?object=::xosoap::visitor::\
      SoapMarshallerVisitor'>xosoap::visitor::SoapMarshallerVisitor</a> 
  serves as demarshaller/ deserializer of SOAP/XML (request) messages.</li>       </ul>
  </p>
  
  @author stefan.sobernig@wu-wien.ac.at
  @creation-date August 18, 2005
  @cvs-id $Id$

}


namespace eval ::xosoap::visitor {

  # # # # # # # # # # #
  # # # # # # # # # # #
  # # staging
  # # # # # # # # # # #
  # # # # # # # # # # #

  namespace import -force ::xosoap::marshaller::*
  namespace import -force ::xosoap::exceptions::*
  namespace import -force ::xorb::datatypes::*
  #namespace import -force ::xosoap::xsd::*

  ###############################################
  # Visitors:
  ###############################################

  ::xotcl::Class AbstractVisitor -ad_doc {

    <p>An class providing an interface to be implemented by 
    each concrete visitor, in particular the method visit.</p> 

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 20 2005

  }
  AbstractVisitor abstract instproc visit {host} 

  ::xotcl::Class SoapMarshallerVisitor -parameter {
    {xmlDoc ""} 
    parentNode
  } -superclass AbstractVisitor -ad_doc {

    <p>This visitor is used to generate a serialized 
    SOAP response message based on the SOAP syntax tree 
    as derived from the initial request and the result
    of invocation (see also <a href='/api-doc/proc-view?proc=\
		       ::xosoap::marshaller::Marshaller+instproc\
		       +marshal'>xosoap::marshaller::Marshaller \
		       marshal</a>).</p> 

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 20 2005

  }

  SoapMarshallerVisitor instproc visit {obj} {
    # / / / / / / / / / / / / / / / / 
    # set parent node for next climb
    set p [$obj info parent]
    if {[::xotcl::Object isobject $p] && \
	    [$p istype ::xosoap::marshaller::SoapElement] && \
	    [$p exists __node__]} {
      my parentNode [$p set __node__]
    } elseif {[my exists parentNode]} {
      # / / / / / / / / / / / / /
      # clear state of visitor 
      # for climbs through a new tree
      # structure
      my unset parentNode
    }
    my SoapElement $obj
  } 

  SoapMarshallerVisitor instproc SoapElement {obj} {
    
    my log "+++[$obj info class] ($obj),[$obj serialize]"
    # / / / / / / / / / / / / / / /
    # staging
    my instvar xmlDoc parentNode
    $obj instvar elementNamespace elementName
    
    # / / / / / / / / / / / / / / /
    # generic marshalling for soap
    # elements

    # / / / / / / / / / / / / / / /
    # 1) root element <or> local node
    if {![info exists parentNode]} {
      set doc [dom createDocument [my getQName $elementNamespace $elementName]]
      set xmlDoc $doc
      set node [$doc documentElement]
    } else {
      set node [$parentNode appendChild \
		    [$xmlDoc createElement [my getQName \
						$elementNamespace $elementName]]]
    }

    # / / / / / / / / / / / / / / / / / / / / /
    # 2) namespace declarations for element's scope
    set nsHandler [$obj resolveNSHandler]
    if {[string first $obj $nsHandler] != "-1"} {
      foreach prefix [$nsHandler getPrefixes] {
	$node setAttribute "xmlns:$prefix" "[$nsHandler get $prefix]"
      }
    }
    
    # / / / / / / / / / / / / / / / / / / / / /
    # 3) encoding declarations for element's scope
    
    set encHandler [$obj resolveEncHandler]
    if {[string first $obj $encHandler] != "-1"} { 
      $node setAttribute "SOAP-ENV:encodingStyle" [join [$encHandler get]]
    }

    # / / / / / / / / / / / / / / / / / / / / /
    # 4) associate doc's node to element object 
    # for contextualising further climbs of visitor
    $obj set __node__ $node

    # / / / / / / / / / / / / / / / / / / / / /
    # 5) element-type-specific marshalling?
    set m [namespace tail [$obj info class]]
    #my log "method-to-call=$m, available? [my info methods]"
    
    # / / / / / / / / / / / / / / / / / /
    # Introducing styles
    set wasStyled 0
    if {[$obj exists style] && [$obj set style] ne {}} {
      my mixin add [$obj set style]::[namespace tail [self class]]
      set wasStyled 1
    }
    if {[lsearch -glob [my info methods] $m] ne "-1"} {
     #my log "CALLED $m"
      my $m $obj
    }
    if {$wasStyled} {
      my mixin delete [$obj set style]::[namespace tail [self class]]
    }
  }

#   SoapMarshallerVisitor instproc SoapBodyResponse {obj} {
#     my instvar xmlDoc parentNode
#     $obj instvar __node__
    
#     # / / / / / / / / / / / / / / / / / / / / / / / /
#     # SOAP 1.1 spec only stipulates / recommends that 
#     # the first child element of SoapBody is suffixed
#     # with *Response. There is no naming convention,
#     # apart from framework-specific ones, on elements
#     # containing the return value(s).
#     # Currently, we provide for a suffix: *Return
#     # TODO: adapt to multiple / complex return values 
#     # (types).

#     #set suffixedName [string map {Response Return} [$obj elementName]]
#     #set returnNode [$__node__ appendChild \
# 	#		[$xmlDoc createElement $suffixedName]]

#     #set valueNode [$returnNode appendChild \
#     #		       [$xmlDoc createTextNode [$obj responseValue]]]
#     # / / / / / / / / / / / / / / / /
#     # introduce anythings and appropriate
#     # delegation to the concrete marshaller
#     # provided by the actual any implementation
#     # TODO: support for multiple anys
#     if {[$obj responseValue] eq {}} {
#       set any [::xosoap::xsd::XsAnything new -isVoid true]
#     } else {
#       set any [$obj responseValue]
#     }
#     set name [string map {Response Return} [$obj elementName]]
#     set anyNode [$__node__ appendChild \
# 		     [$xmlDoc createElement $name]]
#     $any marshal $xmlDoc $anyNode $obj
#   }

  SoapMarshallerVisitor instproc SoapBodyRequest {obj} {
    my instvar xmlDoc parentNode
    $obj instvar methodArgs __node__
    
    # / / / / / / / / / / / / / / / / /
    # Introducing anythings!
    foreach any $methodArgs {
      my log REQUEST-ANY=[$any serialize]
      set anyNode [$__node__ appendChild \
		       [$xmlDoc createElement [$any name__]]]
      $any marshal $xmlDoc $anyNode $obj
    }
    
    #foreach {k v} $methodArgs {
    #  $__node__ appendChild [$xmlDoc createElement \
	#[string trimleft $k "-"]  argEl]
      #$argEl appendChild [$xmlDoc createTextNode $v]
    #}
  }

  SoapMarshallerVisitor instproc SoapFault {obj} {
    my instvar xmlDoc parentNode
    $obj instvar __node__
    # / / / / / / / / / / / / / / / / / / / / / /
    # TODO: The nested elements of SoapFault need
    # to be sequenced. Currently, sequencing is
    # enforced by providing a mere list. Consider
    # integrating SoapFault + child elements into
    # SoapElement infrastructure.
    foreach s [list faultcode faultstring detail] {
      $__node__ appendChild [$xmlDoc createElement $s faultEl]
      $faultEl appendChild [$xmlDoc createTextNode [$obj $s]]
    }
  }

  SoapMarshallerVisitor ad_instproc releaseOn {node} {
    <p>A small helper method to initiate a visitor's 
    crawl over an object tree.</p> 
    
    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August, 20 2005
    
    @param node The top-level or root object of the SOAP syntax/ \
	object tree representing the intial request.
    @param resultValue The result as returned by the actual invocation.
    
  } {
    if {[$node istype ::xosoap::marshaller::SoapElement]} {
      $node accept [self] 
    }
  }

  SoapMarshallerVisitor instproc getQName {prefix localName} {
    set qName $localName
    if {$prefix ne {}} {
      set qName $prefix:$qName
    }
    return $qName
  }

  # # # # # # # # # # # # # # # 
  # # # # # # # # # # # # # # # 
  # # FaultDataVisitor
  # # # # # # # # # # # # # # # 
  # # # # # # # # # # # # # # # 

  ::xotcl::Class FaultDataVisitor -slots {
    Attribute data -default {}
  }
  
  FaultDataVisitor instproc visit {obj} {
    if {[$obj istype ::xosoap::marshaller::SoapFault]} {
      my instvar data
      set data [my show $obj]
    }
  }
  
  FaultDataVisitor instproc show {obj} {
    set c [$obj info class]
    set r {}
    foreach v [$c info slots] {
      set v [namespace tail $v]
      if {[$obj exists $v]} {
	append r [subst {
	  $v: [$obj set $v]
	}]
      }
    }
    return $r
  }
  
  # # # # # # # # # # # # # # # 
  # # # # # # # # # # # # # # # 
  # # InvocationDataVisitor
  # # # # # # # # # # # # # # # 
  # # # # # # # # # # # # # # # 
  ::xotcl::Class InvocationDataVisitor -slots {
    Attribute batch
    Attribute invocationContext -default ::xo::cc
  }
  
  ::xotcl::Class InvocationDataVisitor -parameter {
    scenario
    batch
    {invocationContext ::xo::cc}
  } -superclass AbstractVisitor
  InvocationDataVisitor instproc init args {
    my instvar invocationContext
    # / / / / / / / / / / / / / /
    # solve parameter retrieval problem!
    # set style ::xosoap::RpcLiteral
    # set style ::xosoap::DocumentLiteral
    # / / / / / / / / / / / / / /
    # resolving the style information:
    # 1) for client calls (invocationContext)
    # corresponds to instance of ::xorb::stub::ContextObject
    
    if {[$invocationContext istype ::xosoap::client::SoapGlueObject]} {
      # visitor is initiated from a consumer/ client
      set style [$invocationContext messageStyle]
    } else {
      # visitor is called from within a provider/ server
      set style [parameter::get \
		     -parameter "default_invocation_style" \
		     -package_id [$invocationContext set package_id]]
    }

    my log style=$style
    if {![my exists scenario] || [my scenario] eq {}} {
      foreach scenario [[self class] info children] {
	if {$scenario ne "[self class]::slot"} {
	  $scenario instvar conditions 
	  set jexpr [join $conditions " && "]
	  set evaluation([expr $jexpr],$scenario) $scenario
	}
      }
      set key [array names evaluation 1,*]
      if {[llength $key] ne "1"} {
	error [::xosoap::exceptions::Server::InvocationScenarioException new \
		   "key: $key"]
     }
      set direction [namespace tail $evaluation($key)]
      my scenario ${style}::$direction
    } else {
      set direction [namespace tail [my scenario]]
      my scenario ${style}::$direction
    }
    next
  }
  
  InvocationDataVisitor instproc visit {obj} {
    if {[my isobject $obj]} {
      set m [namespace tail [$obj info class]]
      my mixin add [my scenario]
      if {[lsearch -glob [my info methods] $m] ne "-1"} {
	my $m $obj 
      }
      my mixin delete [my scenario]
    }
  }

  InvocationDataVisitor instproc releaseOn {element} {
    if {[$element istype SoapElement]} {
      $element accept [self]
    }
  }

  # # # # # # # # # # # # # # # 
  # # # # # # # # # # # # # # # 
  # # Scenario: Server, 
  # # i.e. pair of:
  # # - Inbound request
  # # - outbound response
  # # # # # # # # # # # # # # # 
  # # # # # # # # # # # # # # #   
  ::xotcl::Class InvocationDataVisitor::InboundRequest \
      -set conditions {
	{[$invocationContext exists marshalledRequest]}
	{[$invocationContext exists unmarshalledRequest]}
	{![$invocationContext exists virtualCall]}
	{![$invocationContext exists virtualArgs]}
      }
  
  ::xotcl::Class InvocationDataVisitor::OutboundResponse \
      -set conditions {
	{[$invocationContext exists marshalledRequest]}
	{[$invocationContext exists unmarshalledRequest] ne {}}
	{![$invocationContext exists marshalledResponse]}
	{![$invocationContext exists unmarshalledResponse]}
	{[$invocationContext exists virtualCall]}
	{[$invocationContext exists virtualArgs]}
      }
  
  
  # # # # # # # # # # # # # # # 
  # # # # # # # # # # # # # # # 
  # # Scenario: Client, 
  # # i.e. pair of:
  # # - Outbound request
  # # - Inbound response
  # # # # # # # # # # # # # # # 
  # # # # # # # # # # # # # # #   

  ::xotcl::Class InvocationDataVisitor::OutboundRequest \
      -set conditions {
	{![$invocationContext exists marshalledResponse]}
	{![$invocationContext exists unmarshalledResponse]}
	{![$invocationContext exists unmarshalledRequest]}
	{![$invocationContext exists marshalledRequest]}
	{[$invocationContext exists virtualCall]}
	{[$invocationContext exists virtualArgs]}
      }

  ::xotcl::Class InvocationDataVisitor::InboundResponse \
      -set conditions {
	{[$invocationContext exists unmarshalledRequest]}
	{[$invocationContext exists marshalledRequest]}
	{[$invocationContext exists marshalledResponse]}
	{[$invocationContext exists virtualCall]}
	{[$invocationContext exists virtualArgs]}
      }
  
  namespace export AbstractVisitor SoapMarshallerVisitor \
      InvocationDataVisitor FaultDataVisitor
  
}

  #==============================
  #==============================
  
#   ::xotcl::Class SoapRequestVisitor -parameter {
#     serviceMethod
#     serviceArgs
#     {boundness in} 
#     {targetNS ""}
#   } -superclass AbstractVisitor \
#       -ad_doc {

#     <p>This visitor extracts relevant invocation infos, i.e. name of 
#     called remote method and arguments supplied, and stores these in 
#     terms of parameters for later access 
#     (see also <a href='/api-doc/\
# 	 proc-view?proc=::xosoap::marshaller::Marshaller+instproc+marshal'>\
# 	 xosoap::marshaller::Marshaller demarshal</a>).
#     </p> 

#     @author stefan.sobernig@wu-wien.ac.at
#     @creation-date August, 20 2005

#   }

#   SoapRequestVisitor ad_instproc visit {obj} {} {
#     if {[my isobject $obj]} {
#       my instvar boundness
#       switch $boundness {
# 	"in" 	{my mixin RequestInbound}
# 	"out"  	{my mixin RequestOutbound}
#       }
#       eval my [namespace tail [$obj info class]] $obj 
#     }
#   }

#   SoapRequestVisitor configure 	-instproc SoapEnvelope {obj} { next } \
#       -instproc SoapBody {obj} { next } \
#       -instproc SoapHeader {obj} { next } \
#       -instproc SoapBodyRequest {obj} { next } \


#   ::xotcl::Class RequestInbound -ad_instproc SoapBodyRequest {obj} {} {

#     my instvar serviceMethod serviceArgs
    
#     set serviceMethod [$obj elementName]
#     # provide for correct order of argument array
    
#     set tmpArgs ""
    
#     foreach keyvalue [$obj set methodArgs]  {	 
      
#       #my log "i: [lindex $keyvalue 0], j: [lindex $keyvalue 1]"
#       append tmpArgs " " "{[lindex $keyvalue 1]}"     
      
#     }     
    
#     set serviceArgs $tmpArgs
    
#   }

#   ::xotcl::Class RequestOutbound -ad_instproc SoapBodyRequest {obj} {} {

#     my instvar targetNS serviceMethod serviceArgs
#     $obj elementName $serviceMethod
#     $obj set methodArgs $serviceArgs
#     if {$targetNS ne {}} {
#       $obj registerNS [list "m" $targetNS]
#     } 

#   }

  
#   set comment {SoapRequestVisitor ad_instproc visit obj {

#     <p>This method specifies the visitor's operations on each object visited when crawling an object tree. To be more specific,
#     it ignores all objects other than typed <a href='/xotcl/show-object?object=::xosoap::visitor::SoapBodyEntry'>xosoap::visitor::SoapBodyEntry</a>. If a leaf object of this type is reached, it extracts the relevant information.</p>

#     @author stefan.sobernig@wu-wien.ac.at
#     @creation-date August, 20 2005
    
#     @param obj An object of type / derived from <a href='/xotcl/show-object?object=::xosoap::visitor::SoapElement'>xosoap::visitor::SoapElement</a>.


#   } {
    
#     my instvar serviceMethod serviceArgs
    
#     if {[$obj istype ::xosoap::marshaller::SoapBodyEntry]} {

#       set serviceMethod [$obj elementName]
#       # provide for correct order of argument array
      
#       set tmpArgs ""
      
#       foreach keyvalue [$obj set methodArgs]  {	 
	
# 	#my log "i: [lindex $keyvalue 0], j: [lindex $keyvalue 1]"
# 	append tmpArgs " " "{[lindex $keyvalue 1]}"     
	
#       }     
      
#       set serviceArgs $tmpArgs
      
#       #my log "$obj: [my serviceMethod] [my serviceArgs]"
#     }

#   }
#   }

#   SoapRequestVisitor ad_instproc releaseOn node {

#     <p>A small helper method to initiate a visitor's crawl over an object tree.</p> 

#     @author stefan.sobernig@wu-wien.ac.at
#     @creation-date August, 20 2005
    
#     @param node The top-level or root object of the SOAP syntax / object tree representing the intial request.
#     @param resultValue The result as returned by the actual invocation.

#   } {
    
    
    
#     $node accept [self] 
    
    
#   }

#   ::xotcl::Class SoapResponseVisitor -superclass AbstractVisitor -parameter {batch {boundness "out"}}


#   SoapResponseVisitor ad_instproc visit {obj} {} {

#     if {[my isobject $obj]} {
      
#       my instvar boundness
#       switch $boundness {
	
# 	"in" 	{my mixin ResponseInbound}
# 	"out"  	{my mixin ResponseOutbound}
	
#       }
#       eval my [namespace tail [$obj info class]] $obj 
#     }

#   }

#   SoapResponseVisitor ad_instproc releaseOn {node} {} {

#     $node accept [self] 

#   }

#   SoapResponseVisitor configure -instproc SoapEnvelope {obj} { next } \
#       -instproc SoapBody {obj} { next } \
#       -instproc SoapHeader {obj} { next } \
#       -instproc SoapBodyResponse {obj} { next } \
#       -instproc SoapBodyRequest {obj} { next }

#   ::xotcl::Class ResponseOutbound -ad_instproc SoapBodyRequest {obj} {} {
#     $obj class ::xosoap::marshaller::SoapBodyResponse
#     $obj elementName [$obj set targetMethod]Response
#     $obj responseValue [my batch]
#   }

#   ::xotcl::Class ResponseInbound -ad_instproc SoapBodyResponse {obj} {} {

#     my log "+++ i am here"
#     my batch [$obj responseValue]
#     my log "+++ responseValue: [$obj responseValue], batch: [my batch]"

#   }
