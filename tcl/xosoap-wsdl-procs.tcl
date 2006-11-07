ad_library {
	
    WSDL 1.1 support for xorb's SOAP-plugin, xosoap
    see http://www.w3.org/TR/wsdl
		
    @author stefan.sobernig@wu-wien.ac.at
    @creation-date August 18, 2005
    @cvs-id $Id: xosoap-visitor-procs.tcl 11 2006-07-17 19:31:04Z ssoberni $

 }
 
::xosoap::MessageHandler ad_instproc getWSDL -servicePointer:required {} {
	
    # lookup: contract composite
    set bundle [XorbContainer do ::xorb::SCBroker getContract -serialized -name $servicePointer]
	 	
    #my log "bundle=$bundle"
	 	
    set contractPointer [lindex $bundle 0]
	 
    #::xorb::MessageType addOperations {accept}
    ::xotcl::Class ::xorb::Retrievable 
    eval [lindex $bundle 1]
	 
 	 	# unveal / create WSDLVisitor
	 	
    set visitor [::xosoap::visitor::WsdlBuilderVisitor new -volatile]
    $contractPointer accept $visitor	
	 	
    # return WSDL structure
    return "ns_return 200 text/xml {[$visitor asXML]}"
}

namespace eval xosoap::visitor {
    
    ::xotcl::Class WsdlBuilderVisitor
    
    WsdlBuilderVisitor ad_instproc init {} {} {
	
	my instvar ns doc url xsdTypes
	
	set url "[ns_conn location][ns_urldecode [ns_conn url]]"
	set ns(tns) 	"$url?wsdl"
	set ns(soap) "http://schemas.xmlsoap.org/wsdl/soap/"
	set ns(soap-enc) "http://schemas.xmlsoap.org/soap/encoding/"
	set ns(xsd) "http://www.w3.org/2001/XMLSchema"
	set ns(wsdl) "http://schemas.xmlsoap.org/wsdl/"
	
	
	set xsdTypes(string) 	"xsd:string"
	set xsdTypes(integer)	"xsd:integer"
		 		
	
	
	set doc [dom createDocumentNS $ns(wsdl) "wsdl:definitions"]
	
	# add ns declarations
	foreach k [array names ns] {
	    
	    [$doc documentElement] setAttribute "xmlns:$k" $ns($k)
	}
	
    }
    
    WsdlBuilderVisitor ad_instproc visit {obj} {} {
	if {[my isobject $obj]} {
	    eval my [namespace tail [$obj info class]] $obj 
	}
	
    }
    
    WsdlBuilderVisitor ad_instproc asXML {} {} {
	
	my instvar doc
	return [$doc asXML -doctypeDeclaration true]
				
    }
    
    WsdlBuilderVisitor ad_instproc ServiceContract {serviceContract} {} {
	
	my instvar doc ns url elPortType
	
	set current [$doc getElementsByTagName "wsdl:definitions"]
	
	# add attrs to definitions el (doc, name attrs)
	my log current=$current,sc=$serviceContract
	$current setAttribute "name" [$serviceContract label]
	$current setAttribute "targetNamespace" $ns(tns)
	# append service element
	set elService [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:service"]]
	$elService setAttribute "name" [$serviceContract label]
	set elDoc [$elService appendChild [$doc createElementNS $ns(wsdl) "wsdl:documentation"]]
	$elDoc appendChild [$doc createTextNode [$serviceContract description]]
	# append binding element
	set elBinding [$current insertBefore [$doc createElementNS $ns(wsdl) "wsdl:binding"] $elService]
	$elBinding setAttribute "name" "[$serviceContract label]SoapBinding"
	$elBinding setAttribute "type" "tns:[$serviceContract label]PortType"
	set el1SoapBind [$elBinding appendChild [$doc createElementNS $ns(soap) "soap:binding"]]
	$el1SoapBind setAttribute "style" "rpc"
	$el1SoapBind setAttribute "transport" "http://schemas.xmlsoap.org/soap/http"
	# append port element and add port-binding info to service el
	set elPortType [$current insertBefore [$doc createElementNS $ns(wsdl) "wsdl:portType"] $elBinding]
	$elPortType setAttribute "name" "[$serviceContract label]PortType"
	set el1Port [$elService appendChild [$doc createElementNS $ns(wsdl) "wsdl:port"]]
	$el1Port setAttribute "name" "[$serviceContract label]Port"
	$el1Port setAttribute "binding" "tns:[$serviceContract label]SoapBinding"; # tns:[$serviceContract label]SoapBinding?
	set el2Address [$el1Port appendChild [$doc createElementNS $ns(soap) "soap:address"]]
	$el2Address setAttribute "location" $url
    }
    
    WsdlBuilderVisitor ad_instproc Operation {op} {} {
	
	my instvar doc operation ns url
	set operation $op
	
	set current [$doc getElementsByTagName "wsdl:portType"]
	set el1Operation [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:operation"]]
	$el1Operation setAttribute "name" [$operation label]
	
	set current [$doc getElementsByTagName "wsdl:binding"]
	set el1Operation [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:operation"]]
	$el1Operation setAttribute "name" [$operation label]
	set el2SoapOp [$el1Operation appendChild [$doc createElementNS $ns(soap) "soap:operation"]]
	$el2SoapOp setAttribute "soapAction" ${url}/[$operation label]

	::xorb::aux::SortableTypedComposite instfilter add compositeFilter
	#my log "objfilter: [$operation info filter], instfilters: [[$operation info class] info instfilter]"
    }
    
    WsdlBuilderVisitor ad_instproc Input {input} {} {
	
	my instvar doc url operation ns elPortType
	set operationName [$operation label]
	#message element
	set current [$doc documentElement]
	set elMessage [$current insertBefore [$doc createElementNS $ns(wsdl) "wsdl:message"] $elPortType]
	$elMessage setAttribute "name" "${operationName}Input"
	# portType/input
	set xpath [subst {/wsdl:definitions/wsdl:portType/wsdl:operation\[@name='$operationName'\]}]
	my log "+++xml=[$current asXML]"

	set current [$current selectNodes $xpath]
	set el2Input [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:input"]]
	$el2Input setAttribute "message" "tns:${operationName}Input"
	
	# binding/input
	
	set current [$doc documentElement]
	set current [$current selectNodes "/wsdl:definitions/wsdl:binding/wsdl:operation\[@name='$operationName'\]"]
	my log +2current=$current,doc=$doc
	set el2Input [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:input"]]
	set el3SoapBody [$el2Input appendChild [$doc createElementNS $ns(soap) "soap:body"]]
	$el3SoapBody setAttribute "use" "literal"
	$el3SoapBody setAttribute "namespace" $url
	$el3SoapBody setAttribute "encodingStyle" $ns(soap-enc)
	
	
    }
    
    WsdlBuilderVisitor ad_instproc Output {output} {} {
	
	
	my instvar doc url operation ns elPortType
	set operationName [$operation label]
	
	#message element
	set current [$doc getElementsByTagName "wsdl:definitions"]
	set elMessage [$current insertBefore [$doc createElementNS $ns(wsdl) "wsdl:message"] $elPortType]
	$elMessage setAttribute "name" "${operationName}Output"
	
	# portType/input
	
	set current [[$doc documentElement] selectNodes "/wsdl:definitions/wsdl:portType/wsdl:operation\[@name='[$operation label]'\]"]
	set el2Input [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:output"]]
	$el2Input setAttribute "message" "tns:${operationName}Output"
	
	# binding/input
	
	set current [[$doc documentElement] selectNodes "/wsdl:definitions/wsdl:binding/wsdl:operation\[@name='[$operation label]'\]"]
	set el2Input [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:output"]]
	set el3SoapBody [$el2Input appendChild [$doc createElementNS $ns(soap) "soap:body"]]
	$el3SoapBody setAttribute "use" "literal"
	$el3SoapBody setAttribute "namespace" $url
	$el3SoapBody setAttribute "encodingStyle" $ns(soap-enc)
		
    }
    
    WsdlBuilderVisitor ad_instproc Argument {argument} {} {
	
	my instvar doc operation xsdTypes ns
	set current [[$doc documentElement] selectNodes "/wsdl:definitions/wsdl:message\[@name='[$operation label]Input'\]"]
	set el2Argument [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:part"]]
	$el2Argument setAttribute "name" [$argument label]
	$el2Argument setAttribute "type" $xsdTypes([$argument datatype])
	
    }
    
    WsdlBuilderVisitor ad_instproc ReturnValue {returnValue} {} {
	
	my instvar doc operation xsdTypes ns
	set current [[$doc documentElement] selectNodes "/wsdl:definitions/wsdl:message\[@name='[$operation label]Output'\]"]
	set el2Argument [$current appendChild [$doc createElementNS $ns(wsdl) "wsdl:part"]]
	$el2Argument setAttribute "name" [$returnValue label]
	$el2Argument setAttribute "type" $xsdTypes([$returnValue datatype])
    }
}
 	