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
  namespace import -force ::xorb::datatypes::*

  ::xotcl::Class Wsdl1.1Builder -slots {
    Attribute contract
    Attribute xml
    Attribute style
  } -set ns(soap) "http://schemas.xmlsoap.org/wsdl/soap/" \
      -set ns(soap-enc) "http://schemas.xmlsoap.org/soap/encoding/" \
      -set ns(xsd) "http://www.w3.org/2001/XMLSchema" \
      -set ns(wsdl) "http://schemas.xmlsoap.org/wsdl/" \
      -set ns(xsd1) {$url/}
  Wsdl1.1Builder instproc init {} {
    my instvar contract xml url doc style
    if {[$contract istype ServiceContract]} {
      set url [ns_conn location][::xo::cc url]
      # / / / / / / / / / / / / / / / / /
      # 1) write out the general contract
      # information to the wsdl document
      [my info class] instvar ns
      my instvar doc elPortType
      set doc [dom createDocumentNS $ns(wsdl) "wsdl:definitions"]
      foreach k [array names ns] {
	[$doc documentElement] setAttribute "xmlns:$k" [subst $ns($k)]
      }
      set current [$doc getElementsByTagName "wsdl:definitions"]
      
      # add attrs to definitions el (doc, name attrs)
      $current setAttribute "name" [$contract name]
      $current setAttribute "targetNamespace" [subst $ns(xsd1)]

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
			  type xsd1:[$contract name]PortType] {
			    soap:binding {
			      transport http://schemas.xmlsoap.org/soap/http
			    } {}
			  }
	wsdl:service [list name [$contract name]] {
	  wsdl:documentation [list t [$contract description]]
	  wsdl:port [list name [$contract name]Port \
			 binding xsd1:[$contract name]SoapBinding] {
			   soap:address [list location $url] {}
			   
			 }
	}
      }
      
      # / / / / / / / / / / / / / / / / /
      # 2) proceed to operations
      my mixin add ${style}::[namespace tail [self class]]
      foreach a [$contract info slots] {
	set t [namespace tail [$a info class]]
	my $t $a
      }
      my mixin delete ${style}::[namespace tail [self class]]
      #my log XML=[$current asXML]
      
      # / / / / / / / / / / / / / / / / /
      # 3) proceed to types (if any)
      my instvar types
      if {[array exists types]} {
	dom createNodeCmd elementNode xsd:element
	dom createNodeCmd elementNode xsd:complexType
	dom createNodeCmd elementNode xsd:all
	dom createNodeCmd elementNode xsd:sequence
	dom createNodeCmd elementNode wsdl:types
	dom createNodeCmd elementNode xsd:schema

	set tlist {} 
	my log TYPES=[array get types]
	foreach {key desc} [array get types] {
	  append tlist $desc
	}
	
	$current insertBeforeFromScript [subst {
	    wsdl:types {} {
	      xsd:schema {targetNamespace ${url}/} {
		$tlist
	      }
	    }
	}] [$current firstChild]
      }
      set xml [$current asXML]
    }        
  }
  
  RpcLiteral contains {
    Class Wsdl1.1Builder -instproc Abstract {obj} {
      [my info class] instvar ns
      my instvar url doc types style
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
      set typeNodes {}
      foreach arg $arguments {
	set idx [string first : $arg]
	# / / / / / / / / / / / / / / / / / /
	# TODO: parse resolution to anythings!
	set name [string range $arg 0 [expr {$idx-1}]]
	set type [string range $arg [expr {$idx+1}] end]
	set ar [::xorb::datatypes::AnyReader new \
		    -typecode $type \
		    -name $name \
		    -observer [self] \
		    -style $style]
	append argNodes "wsdl:part {name $name type [$ar get xsType]} {}"
	# / / / / / / / / / / /
	# retrieve xs type definitions
	# will populate the instance variable
	# 'types' with a appropriate dom
	# generation scripts
	$ar get xsDescription
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
	set ar [::xorb::datatypes::AnyReader new \
		    -name $name \
		    -observer [self] \
		    -typecode $type \
		    -style $style] 
	append returnNodes "wsdl:part {name $name type [$ar get xsType]} {}"
	# / / / / / / / / / / /
	# retrieve xs type definitions
	# will populate the instance variable
	# 'types' with a appropriate dom
	# generation scripts
	$ar get xsDescription
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
	  wsdl:input [list message "xsd1:[$obj name]Input"] {}
	  wsdl:output [list message "xsd1:[$obj name]Output"] {}
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
  }
  
  DocumentLiteral contains {
    Class Wsdl1.1Builder -instproc Abstract {obj} {
      [my info class] instvar ns
      my instvar url doc types style
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
      $obj instvar arguments returns name
      set upperName [string toupper $name 0 0]
      set portType [$doc getElementsByTagName "wsdl:portType"]

      set argNodes {}
      set typeNodes {}
      foreach arg $arguments {
	set idx [string first : $arg]
	# / / / / / / / / / / / / / / / / / /
	# TODO: parse resolution to anythings!
	set argName [string range $arg 0 [expr {$idx-1}]]
	set type [string range $arg [expr {$idx+1}] end]
	set ar [::xorb::datatypes::AnyReader new \
		    -typecode $type \
		    -name $argName \
		    -observer [self] \
		    -style $style]
	set upperArgName [string toupper $argName 0 0]
	append argNodes [subst {
	  wsdl:part {
	    name $argName element [$ar get xsType]
	  } {}
	}]
	# / / / / / / / / / / /
	# retrieve xs type definitions
	# will populate the instance variable
	# 'types' with a appropriate dom
	# generation scripts
	$ar get xsDescription
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
	set returnName [string range $r 0 [expr {$idx-1}]]
	set type [string range $r [expr {$idx+1}] end]
	set ar [::xorb::datatypes::AnyReader new \
		    -name $returnName \
		    -observer [self] \
		    -typecode $type \
		    -style $style]
	# / / / / / / / / / / / / / / / /
	# No type, but element reference!
	append returnNodes [subst {
	  wsdl:part {name $returnName element [$ar get xsType]} {}
	}]
	# / / / / / / / / / / /
	# retrieve xs type definitions
	# will populate the instance variable
	# 'types' with a appropriate dom
	# generation scripts
	$ar get xsDescription
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
	  wsdl:input [list message "xsd1:[$obj name]Input"] {}
	  wsdl:output [list message "xsd1:[$obj name]Output"] {}
	}
      }
      
      set binding [$doc getElementsByTagName "wsdl:binding"]
      $binding appendFromScript {
	wsdl:operation [list name [$obj name]] {
	  soap:operation [list style document soapAction ${url}/[$obj name]] {}
	  wsdl:input {} {
	    soap:body \
		[list use literal] {}
	  }
	  wsdl:output {} {
	    soap:body \
		[list use literal] {}
	  }
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
      # / / / / / / / / / / / / / / / /
      # TODO: get style in a CoR:
      # - per-implementation
      # - package
      # ...
      set style [parameter::get \
		     -parameter "default_invocation_style" \
		     -package_id [::xo::cc set package_id]]
      #set style ::xosoap::DocumentLiteral
      set b [Wsdl1.1Builder new \
		 -contract $obj \
		 -style $style \
		 -volatile]
    } catch {error e} {
      global errorInfo
      [WsdlGenerationException new "Reason: '$errorInfo'"] write
    }
    if {$b ne {}} {
      ns_return 200 text/xml [$b xml]
    }
  }
  
  namespace export Wsdl1.1 Wsdl1.1Builder
  
  # # # # # # # # # # # 
  # # # # # # # # # # # 
  # # # # # # # # # # # 
  # # # # # # # # # # # 
  
}