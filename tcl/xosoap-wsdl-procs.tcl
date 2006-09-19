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
	 	
	 	
	 	set contractPointer [lindex $bundle 0]
	 	
	 	#::xorb::MessageType addOperations {accept}
	 	
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
		 		set ns(xsd) "http://www.w3.org/2000/10/XMLSchema"
		 		
	
		 		set xsdTypes(string) 	"xsd:string"
		 		set xsdTypes(integer)	"xsd:integer"
		 		
		 		
		 		
		 		set doc [dom createDocument "definitions"]
		 		
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
				
				my instvar doc ns url
				
				set current [$doc getElementsByTagName "definitions"]
				
				# add attrs to definitions el (doc, name attrs)
				$current setAttribute "name" [$serviceContract label]
				$current setAttribute "targetNamespace" $ns(tns)
				# append service element
				set elService [$current appendChild [$doc createElement "service"]]
				$elService appendChild [$doc createTextNode [$serviceContract description]]
				# append binding element
				set elBinding [$current appendChild [$doc createElement "binding"]]
				$elBinding setAttribute "name" "[$serviceContract label]SoapBinding"
				$elBinding setAttribute "type" "tns:[$serviceContract label]PortType"
				set el1SoapBind [$elBinding appendChild [$doc createElement "soap:binding"]]
				$el1SoapBind setAttribute "stlye" "rpc"
				$el1SoapBind setAttribute "transport" "http://schemas.xmlsoap.org/soap/http"
				# append port element and add port-binding info to service el
				set elPortType [$current appendChild [$doc createElement "portType"]]
				$elPortType setAttribute "name" "[$serviceContract label]PortType"
				set el1Port [$elService appendChild [$doc createElement "port"]]
				$el1Port setAttribute "name" "[$serviceContract label]Port"
				$el1Port setAttribute "binding" "tns:[$serviceContract label]Binding"; # tns:[$serviceContract label]SoapBinding?
				set el2Address [$el1Port appendChild [$doc createElement "soap:address"]]
				$el2Address setAttribute "location" $url
			
		
		}
	 
	 	WsdlBuilderVisitor ad_instproc Operation {op} {} {
		
				my instvar doc operation
				set operation $op
			
				set current [$doc getElementsByTagName "portType"]
				set el1Operation [$current appendChild [$doc createElement "operation"]]
				$el1Operation setAttribute "name" [$operation label]
				
				set current [$doc getElementsByTagName "binding"]
				set el1Operation [$current appendChild [$doc createElement "operation"]]
				$el1Operation setAttribute "name" [$operation label]
				
				::xorb::aux::SortableTypedComposite instfilter add compositeFilter
				my log "objfilter: [$operation info filter], instfilters: [[$operation info class] info instfilter]"
		}
 		
 		WsdlBuilderVisitor ad_instproc Input {input} {} {
		
				my instvar doc url operation
				set operationName [$operation label]
				my log "+++ opName: $operationName"
				#message element
				set current [$doc getElementsByTagName "definitions"]
				my log "+++ current:$current"
				set elMessage [$current appendChild [$doc createElement "message"]]
				$elMessage setAttribute "name" "${operationName}Input"
				
				# portType/input
				
				set current [[$doc documentElement] selectNodes "/definitions/portType/operation\[@name='[$operation label]'\]"]
				set el2Input [$current appendChild [$doc createElement "input"]]
				$el2Input setAttribute "message" "tns:${operationName}Input"
				
				# binding/input
				
				set current [[$doc documentElement] selectNodes "/definitions/binding/operation\[@name='[$operation label]'\]"]
				set el2Input [$current appendChild [$doc createElement "input"]]
				set el3SoapBody [$el2Input appendChild [$doc createElement "soap:body"]]
				$el3SoapBody setAttribute "use" "encoded"
				$el3SoapBody setAttribute "namespace" $url
				$el3SoapBody setAttribute "encodingStyle" "http://schemas.xmlsoap.org/soap/encoding/"
				
				
		}
		
		WsdlBuilderVisitor ad_instproc Output {output} {} {
		
		
				my instvar doc url operation
				set operationName [$operation label]
				
				#message element
				set current [$doc getElementsByTagName "definitions"]
				set elMessage [$current appendChild [$doc createElement "message"]]
				$elMessage setAttribute "name" "${operationName}Output"
				
				# portType/input
				
				set current [[$doc documentElement] selectNodes "/definitions/portType/operation\[@name='[$operation label]'\]"]
				set el2Input [$current appendChild [$doc createElement "output"]]
				$el2Input setAttribute "message" "tns:${operationName}Output"
				
				# binding/input
				
				set current [[$doc documentElement] selectNodes "/definitions/binding/operation\[@name='[$operation label]'\]"]
				set el2Input [$current appendChild [$doc createElement "output"]]
				set el3SoapBody [$el2Input appendChild [$doc createElement "soap:body"]]
				$el3SoapBody setAttribute "use" "encoded"
				$el3SoapBody setAttribute "namespace" $url
				$el3SoapBody setAttribute "encodingStyle" "http://schemas.xmlsoap.org/soap/encoding/"
		
		}
		
		WsdlBuilderVisitor ad_instproc Argument {argument} {} {
				
				my instvar doc operation xsdTypes
				set current [[$doc documentElement] selectNodes "/definitions/message\[@name='[$operation label]Input'\]"]
				set el2Argument [$current appendChild [$doc createElement "part"]]
				$el2Argument setAttribute "name" [$argument label]
				$el2Argument setAttribute "type" $xsdTypes([$argument datatype])
				
		}
		
		WsdlBuilderVisitor ad_instproc ReturnValue {returnValue} {} {
		
				my instvar doc operation xsdTypes
				set current [[$doc documentElement] selectNodes "/definitions/message\[@name='[$operation label]Output'\]"]
				set el2Argument [$current appendChild [$doc createElement "part"]]
				$el2Argument setAttribute "name" [$returnValue label]
				$el2Argument setAttribute "type" $xsdTypes([$returnValue datatype])
		}
 	}
 	