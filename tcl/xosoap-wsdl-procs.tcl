ad_library {
	
    WSDL 1.1 support for xorb's SOAP-plugin, xosoap
    - see http://www.w3.org/TR/wsdl
    Validated by means of Mindreef WSDL Validator
    - http://mindreef.net/tide/scopeit/start.do
    
    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August 18, 2005
    @cvs-id $Id$
    
  }

namespace eval ::xosoap {
  namespace import ::xorb::*
  ::xotcl::Class Wsdl1.1Builder -slots {
    Attribute contract
    Attribute xml
  } -set ns(tns) {$url/} \
      -set ns(soap) "http://schemas.xmlsoap.org/wsdl/soap/" \
      -set ns(soap-enc) "http://schemas.xmlsoap.org/soap/encoding/" \
      -set ns(xsd) "http://www.w3.org/2001/XMLSchema" \
      -set ns(wsdl) "http://schemas.xmlsoap.org/wsdl/"
  
  Wsdl1.1Builder instproc init {} {
    my instvar contract xml url doc
    if {[$contract istype ServiceContract]} {
      set url [ns_conn location][::xo::cc url]
      # / / / / / / / / / / / / / / / / /
      # 1) write out the general contract
      # information to the wsdl document
      [self class] instvar ns
      my instvar doc elPortType
      set doc [dom createDocumentNS $ns(wsdl) "wsdl:definitions"]
      foreach k [array names ns] {
	[$doc documentElement] setAttribute "xmlns:$k" $ns($k)
      }
      set current [$doc getElementsByTagName "wsdl:definitions"]
      
      # add attrs to definitions el (doc, name attrs)
      $current setAttribute "name" [$contract name]
      $current setAttribute "targetNamespace" [subst $ns(tns)]

      # # # # # # # # # # # # # # # # # #
      # # 1) stage
      # # # # # # # # # # # # # # # # # #
      dom createNodeCmd elementNode wsdl:portType
      dom createNodeCmd elementNode wsdl:binding
      dom createNodeCmd elementNode soap:binding
      dom createNodeCmd elementNode wsdl:service
      dom createNodeCmd elementNode wsdl:documentation
      dom createNodeCmd elementNode wsdl:port
      dom createNodeCmd elementNode soap:address
      dom createNodeCmd textNode t

      $current appendFromScript {
	wsdl:portType [list name [$contract name]PortType] {}
	wsdl:binding [list name [$contract name]SoapBinding \
			  type tns:[$contract name]PortType] {
			    soap:binding {
			      transport http://schemas.xmlsoap.org/soap/http
			    } {}
			  }
	wsdl:service [list name [$contract name]] {
	  wsdl:documentation [list t [$contract description]]
	}
	wsdl:port [list name [$contract name]Port \
		       binding tns:[$contract name]SoapBinding] {
			 soap:address [list location $url] {}
		       }
      }
         
      # / / / / / / / / / / / / / / / / /
      # 2) proceed to operations

      foreach a [$contract info slots] {
	set t [namespace tail [$a info class]]
	my $t $a
      }
      #my log XML=[$current asXML]
      set xml [$current asXML]
    }        
  }
  
  Wsdl1.1Builder instproc Abstract {obj} {
    [self class] instvar ns
    my instvar url doc
    set current [$doc documentElement]
    # / / / / / / / / / / / / / / / / /
    # 1) register elements
    dom createNodeCmd elementNode wsdl:operation
    dom createNodeCmd elementNode soap:operation
    dom createNodeCmd elementNode wsdl:message
    dom createNodeCmd elementNode wsdl:portType
    dom createNodeCmd elementNode wsdl:input
    dom createNodeCmd elementNode wsdl:output
    dom createNodeCmd elementNode wsdl:part
    dom createNodeCmd elementNode soap:body

    # / / / / / / / / / / / / / / / / /
    # 2) stream input
    $obj instvar arguments returns
    set portType [$doc getElementsByTagName "wsdl:portType"]

    set argNodes {}
    foreach arg $arguments {
      set idx [string first : $arg]
      # / / / / / / / / / / / / / / / / / /
      # TODO: parse resolution to anythings!
      set name [string range $arg 0 [expr {$idx-1}]]
      set type [string range $arg [expr {$idx+1}] end]
      append argNodes "wsdl:part {name $name type $type} {}"
    }
    
    $current insertBeforeFromScript [subst {
      wsdl:message [list "name" "[$obj name]Input"] {
	$argNodes
      } 
    }] $portType

    # / / / / / / / / / / / / / / / / /
    # 3) stream output
  
    set returnNodes {}
    foreach r $returns {
      set idx [string first : $r]
      # / / / / / / / / / / / / / / / / / /
      # TODO: parse resolution to anythings!
      set name [string range $r 0 [expr {$idx-1}]]
      set type [string range $r [expr {$idx+1}] end]
      append returnNodes "wsdl:part {name $name type $type} {}"
    }
    
    $current insertBeforeFromScript [subst {
      wsdl:message [list "name" "[$obj name]Output"] {
	$returnNodes
      } 
    }] $portType
        
    # / / / / / / / / / / / / / / / / /
    # 4) portType + binding: input + output
  
    $portType appendFromScript {
      wsdl:operation [list "name" [$obj name]] {
	wsdl:input [list message "tns:[$obj name]Input"] {}
	wsdl:output [list message "tns:[$obj name]Output"] {}
      }
    }
  
    set binding [$doc getElementsByTagName "wsdl:binding"]
    
    $binding appendFromScript {
      wsdl:operation [list name [$obj name]] {
	soap:operation [list style rpc soapAction ${url}/[$obj name]] {}
	wsdl:input {} {
	  soap:body \
	      [list use literal namespace $url encodingStyle $ns(soap-enc)] {}
	}
	wsdl:output {} {
	  soap:body \
	      [list use literal namespace $url encodingStyle $ns(soap-enc)] {}
	}
      }
    }
  }
  
  ::xotcl::Class Wsdl1.1
  Wsdl1.1 instproc getContract {
    -lightweight:switch 
    -name:required
  } {
    set obj [next];# Skeleton(Cache)->getContract
    #my log "CONTRACT=[$obj serialize]"
    set b [Wsdl1.1Builder new -contract $obj -volatile]
    ns_return 200 text/xml [$b xml]
  }
  
  namespace export Wsdl1.1 Wsdl1.1Builder
  
  # # # # # # # # # # # 
  # # # # # # # # # # # 
  # # # # # # # # # # # 
  # # # # # # # # # # # 
  
}

# ::xorb::RequestHandler ad_instproc getWSDL -servicePointer:required {} {
	
#     # lookup: contract composite
#     set bundle [XorbContainer do ::xorb::SCBroker getContract -serialized -name $servicePointer]
	 	
#     #my log "bundle=$bundle"
	 	
#     set contractPointer [lindex $bundle 0]
	 
#     #::xorb::MessageType addOperations {accept}
#     ::xotcl::Class ::xorb::Retrievable 
#     eval [lindex $bundle 1]
	 
#  	 	# unveal / create WSDLVisitor
	 	
#     set visitor [::xosoap::visitor::WsdlBuilderVisitor new -volatile]
#     $contractPointer accept $visitor	
	 	
#     # return WSDL structure
#     return "ns_return 200 text/xml {[$visitor asXML]}"
# }

# namespace eval xosoap::visitor {
    
#     ::xotcl::Class WsdlBuilderVisitor
    
#     WsdlBuilderVisitor ad_instproc init {} {} {
	
# 	my instvar ns doc url xsdTypes
	
# 	set url "[ns_conn location][ns_urldecode [ns_conn url]]"
# 	set ns(tns) 	"$url?wsdl"
# 	set ns(soap) "http://schemas.xmlsoap.org/wsdl/soap/"
# 	set ns(soap-enc) "http://schemas.xmlsoap.org/soap/encoding/"
# 	set ns(xsd) "http://www.w3.org/2001/XMLSchema"
# 	set ns(wsdl) "http://schemas.xmlsoap.org/wsdl/"
	
	
# 	set xsdTypes(string) 	"xsd:string"
# 	set xsdTypes(integer)	"xsd:integer"
		 		
	
	
# 	set doc [dom createDocumentNS $ns(wsdl) "wsdl:definitions"]
	
# 	# add ns declarations
# 	foreach k [array names ns] {
	    
# 	    [$doc documentElement] setAttribute "xmlns:$k" $ns($k)
# 	}
	
#     }
    
#     WsdlBuilderVisitor ad_instproc visit {obj} {} {
# 	if {[my isobject $obj]} {
# 	    eval my [namespace tail [$obj info class]] $obj 
# 	}
	
#     }
    
#     WsdlBuilderVisitor ad_instproc asXML {} {} {
	
# 	my instvar doc
# 	return [$doc asXML -doctypeDeclaration true]
				
#     }
    
#     WsdlBuilderVisitor ad_instproc ServiceContract {serviceContract} {} {
	
# 	my instvar doc ns url elPortType
	
# 	set current [$doc getElementsByTagName "wsdl:definitions"]
	
# 	# add attrs to definitions el (doc, name attrs)
# 	my log current=$current,sc=$serviceContract
# 	$current setAttribute "name" [$serviceContract label]
# 	$current setAttribute "targetNamespace" $ns(tns)
# 	# append service element
# 	set elService [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:service"]]
# 	$elService setAttribute "name" [$serviceContract label]
# 	set elDoc [$elService appendChild [$doc createElementNS $ns(wsdl) "wsdl:documentation"]]
# 	$elDoc appendChild [$doc createTextNode [$serviceContract description]]
# 	# append binding element
# 	set elBinding [$current insertBefore [$doc createElementNS $ns(wsdl) "wsdl:binding"] $elService]
# 	$elBinding setAttribute "name" "[$serviceContract label]SoapBinding"
# 	$elBinding setAttribute "type" "tns:[$serviceContract label]PortType"
# 	set el1SoapBind [$elBinding appendChild [$doc createElementNS $ns(soap) "soap:binding"]]
# 	$el1SoapBind setAttribute "style" "rpc"
# 	$el1SoapBind setAttribute "transport" "http://schemas.xmlsoap.org/soap/http"
# 	# append port element and add port-binding info to service el
# 	set elPortType [$current insertBefore [$doc createElementNS $ns(wsdl) "wsdl:portType"] $elBinding]
# 	$elPortType setAttribute "name" "[$serviceContract label]PortType"
# 	set el1Port [$elService appendChild [$doc createElementNS $ns(wsdl) "wsdl:port"]]
# 	$el1Port setAttribute "name" "[$serviceContract label]Port"
# 	$el1Port setAttribute "binding" "tns:[$serviceContract label]SoapBinding"; # tns:[$serviceContract label]SoapBinding?
# 	set el2Address [$el1Port appendChild [$doc createElementNS $ns(soap) "soap:address"]]
# 	$el2Address setAttribute "location" $url
#     }
    
#     WsdlBuilderVisitor ad_instproc Operation {op} {} {
	
# 	my instvar doc operation ns url
# 	set operation $op
	
# 	set current [$doc getElementsByTagName "wsdl:portType"]
# 	set el1Operation [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:operation"]]
# 	$el1Operation setAttribute "name" [$operation label]
	
# 	set current [$doc getElementsByTagName "wsdl:binding"]
# 	set el1Operation [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:operation"]]
# 	$el1Operation setAttribute "name" [$operation label]
# 	set el2SoapOp [$el1Operation appendChild [$doc createElementNS $ns(soap) "soap:operation"]]
# 	$el2SoapOp setAttribute "soapAction" ${url}/[$operation label]

# 	::xorb::aux::SortableTypedComposite instfilter add compositeFilter
# 	#my log "objfilter: [$operation info filter], instfilters: [[$operation info class] info instfilter]"
#     }
    
#     WsdlBuilderVisitor ad_instproc Input {input} {} {
	
# 	my instvar doc url operation ns elPortType
# 	set operationName [$operation label]
# 	#message element
# 	set current [$doc documentElement]
# 	set elMessage [$current insertBefore [$doc createElementNS $ns(wsdl) "wsdl:message"] $elPortType]
# 	$elMessage setAttribute "name" "${operationName}Input"
# 	# portType/input
# 	set xpath [subst {/wsdl:definitions/wsdl:portType/wsdl:operation\[@name='$operationName'\]}]
# 	my log "+++xml=[$current asXML]"

# 	set current [$current selectNodes $xpath]
# 	set el2Input [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:input"]]
# 	$el2Input setAttribute "message" "tns:${operationName}Input"
	
# 	# binding/input
	
# 	set current [$doc documentElement]
# 	set current [$current selectNodes "/wsdl:definitions/wsdl:binding/wsdl:operation\[@name='$operationName'\]"]
# 	my log +2current=$current,doc=$doc
# 	set el2Input [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:input"]]
# 	set el3SoapBody [$el2Input appendChild [$doc createElementNS $ns(soap) "soap:body"]]
# 	$el3SoapBody setAttribute "use" "literal"
# 	$el3SoapBody setAttribute "namespace" $url
# 	$el3SoapBody setAttribute "encodingStyle" $ns(soap-enc)
	
	
#     }
    
#     WsdlBuilderVisitor ad_instproc Output {output} {} {
	
	
# 	my instvar doc url operation ns elPortType
# 	set operationName [$operation label]
	
# 	#message element
# 	set current [$doc getElementsByTagName "wsdl:definitions"]
# 	set elMessage [$current insertBefore [$doc createElementNS $ns(wsdl) "wsdl:message"] $elPortType]
# 	$elMessage setAttribute "name" "${operationName}Output"
	
# 	# portType/input
	
# 	set current [[$doc documentElement] selectNodes "/wsdl:definitions/wsdl:portType/wsdl:operation\[@name='[$operation label]'\]"]
# 	set el2Input [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:output"]]
# 	$el2Input setAttribute "message" "tns:${operationName}Output"
	
# 	# binding/input
	
# 	set current [[$doc documentElement] selectNodes "/wsdl:definitions/wsdl:binding/wsdl:operation\[@name='[$operation label]'\]"]
# 	set el2Input [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:output"]]
# 	set el3SoapBody [$el2Input appendChild [$doc createElementNS $ns(soap) "soap:body"]]
# 	$el3SoapBody setAttribute "use" "literal"
# 	$el3SoapBody setAttribute "namespace" $url
# 	$el3SoapBody setAttribute "encodingStyle" $ns(soap-enc)
		
#     }
    
#     WsdlBuilderVisitor ad_instproc Argument {argument} {} {
	
# 	my instvar doc operation xsdTypes ns
# 	set current [[$doc documentElement] selectNodes "/wsdl:definitions/wsdl:message\[@name='[$operation label]Input'\]"]
# 	set el2Argument [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:part"]]
# 	$el2Argument setAttribute "name" [$argument label]
# 	$el2Argument setAttribute "type" $xsdTypes([$argument datatype])
	
#     }
    
#     WsdlBuilderVisitor ad_instproc ReturnValue {returnValue} {} {
	
# 	my instvar doc operation xsdTypes ns
# 	set current [[$doc documentElement] selectNodes "/wsdl:definitions/wsdl:message\[@name='[$operation label]Output'\]"]
# 	set el2Argument [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:part"]]
# 	$el2Argument setAttribute "name" [$returnValue label]
# 	$el2Argument setAttribute "type" $xsdTypes([$returnValue datatype])
#     }
# }
 	