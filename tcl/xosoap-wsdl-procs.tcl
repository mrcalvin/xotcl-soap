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
  namespace import -force ::xoexception::try
  namespace import -force ::xosoap::exceptions::*

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
    try {
      set b [Wsdl1.1Builder new -contract $obj -volatile]
    } catch {error e} {
      [WsdlGenerationException new "Reason: '$e'"] write
    }
    ns_return 200 text/xml [$b xml]
  }
  
  namespace export Wsdl1.1 Wsdl1.1Builder
  
  # # # # # # # # # # # 
  # # # # # # # # # # # 
  # # # # # # # # # # # 
  # # # # # # # # # # # 
  
}