::xo::library configure -doc {
  
  WSDL 1.1 support for xorb's SOAP-plugin, xosoap
  - see http://www.w3.org/TR/wsdl
  Validated by means of Mindreef WSDL Validator
  - http://mindreef.net/tide/scopeit/start.do
  
  @author stefan.sobernig@wu-wien.ac.at
  @creation-date August 18, 2005
  @cvs-id $Id$
  
} -require 15-xosoap-procs

namespace eval ::xosoap {
  namespace import ::xorb::*
  namespace import -force ::xoexception::try
  namespace import -force ::xosoap::exceptions::*
  namespace import -force ::xorb::datatypes::*

  ::xotcl::Class Wsdl1.1Builder -slots {
    Attribute contract
    Attribute xmlDoc
    Attribute style
  } -set ns(soap) 	"http://schemas.xmlsoap.org/wsdl/soap/" \
      -set ns(soap-enc) "http://schemas.xmlsoap.org/soap/encoding/" \
      -set ns(xsd) 	"http://www.w3.org/2001/XMLSchema" \
      -set ns(wsdl) 	"http://schemas.xmlsoap.org/wsdl/" \
      -set ns(types) 	{$url/types/} \
      -set ns(tns)	{$url/} \
      -array set styles {
	::xosoap::RpcEncoded {
	  rpc encoded
	}
	::xosoap::RpcLiteral {
	  rpc literal
	}
	::xosoap::DocumentLiteral {
	  document literal
	}
      }
  Wsdl1.1Builder instproc init {} {
    my instvar contract xmlDoc url doc style bpCompliant
    [self class] instvar styles
    if {[$contract istype ServiceContract]} {
      set url [ad_url][::xo::cc url]
      # / / / / / / / / / / / / / / / / /
      # 1) write out the general contract
      # information to the wsdl document
      [self class] instvar ns
      my instvar doc elPortType
      set doc [dom createDocumentNS $ns(wsdl) "wsdl:definitions"]
      foreach k [array names ns] {
	[$doc documentElement] setAttribute "xmlns:$k" [subst $ns($k)]
      }
      set current [$doc getElementsByTagName "wsdl:definitions"]
      
      # add attrs to definitions el (doc, name attrs)
      # / / / / / / / / / / / / / / / / /
      # NOTE: Most name attributes require
      # to be valid 'name tokens' as defined
      # by the the XML 1.0 specification.
      # Qualified (XO)Tcl names are therefore
      # allowed (this is according to WSDL 1.1)
      # However, WS-I basic profile 1.1 is stricter,
      # it requires (according to profile item BP2703)
      # name attributes etc. to be of type NCName,
      # which is all XML chars without ":"
      # We, therefore, change to the canonicalName
      # as input for wsdl marshaling, given that
      # we are in WS-I BP compat mode.
      set packageId [::xo::cc package_id]
      set bpCompliant [::$packageId get_parameter wsi_bp_compliant 1]
      set cName [$contract contract_name]
      if {$bpCompliant} {
	set cName [$contract canonicalName]
      }
      $current setAttribute "name" $cName
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

      # / / / / / / / / / / / / / / / / /
      # WS-I BP 1.0/1.1
      # R2705: Does not allow for
      # mixed styled bindings; compliance 
      # requires:
      # a-) to have a style attribute
      # for the entire soap:binding
      # scope
      # b-) no per-operation style settings
      # that would overrule according
      # to WSDL 1.1
      set soapBindingAttr(transport) http://schemas.xmlsoap.org/soap/http
      if {$bpCompliant} {
	foreach {mStyle encStyle} $styles($style) break;
	set soapBindingAttr(style) $mStyle
      }

      $current appendFromScript {
	wsdl:portType [list name ${cName}PortType] {}
	wsdl:binding [list name ${cName}SoapBinding \
			  type tns:${cName}PortType] {
			    soap:binding [array get soapBindingAttr] {}
			  }
	wsdl:service [list name $cName] {
	  wsdl:documentation [list t [$contract description]]
	  wsdl:port [list name ${cName}Port \
			 binding tns:${cName}SoapBinding] {
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
	dom createNodeCmd elementNode xsd:complexContent
	dom createNodeCmd elementNode restriction
	dom createNodeCmd elementNode attribute

	set tlist {} 
	my debug TYPES=[array get types]
	foreach {key desc} [array get types] {
	  append tlist $desc
	}
	
	$current insertBeforeFromScript [subst {
	    wsdl:types {} {
	      xsd:schema {targetNamespace [subst $ns(types)]} {
		$tlist
	      }
	    }
	}] [$current firstChild]
      }
      set xmlDoc $doc
    }        
  }

  RpcEncoded contains {
    Class Wsdl1.1Builder -instproc Abstract {obj} {
      [my info class] instvar ns styles
      my instvar url doc types style bpCompliant
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
		    -style $style \
		    -protocol ::xosoap::Soap]
	append argNodes [subst {
	  wsdl:part {
	    name $name type [$ar get xsType]
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
	set name [string range $r 0 [expr {$idx-1}]]
	set type [string range $r [expr {$idx+1}] end]
	set ar [::xorb::datatypes::AnyReader new \
		    -name $name \
		    -observer [self] \
		    -typecode $type \
		    -style $style \
		    -protocol ::xosoap::Soap] 
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
	  wsdl:input [list message "tns:[$obj name]Input"] {}
	  wsdl:output [list message "tns:[$obj name]Output"] {}
	}
      }

      # / / / / / / / / / / / / / / / / /
      # WS-I BP 1.0/1.1
      # R2705: Does not allow for
      # mixed styled bindings; compliance 
      # requires:
      # a-) to have a style attribute
      # for the entire soap:binding
      # scope
      # b-) no per-operation style settings
      # that would overrule according
      # to WSDL 1.1
      set soapOperationAttr(soapAction) ${url}/[$obj name]
      if {!$bpCompliant} {
	foreach {mStyle encStyle} $styles($style) break;
	set soapOperationAttr(style) $mStyle
      }

      set binding [$doc getElementsByTagName "wsdl:binding"]
      $binding appendFromScript {
	wsdl:operation [list name [$obj name]] {
	  soap:operation [array get soapOperationAttr] {}
	  wsdl:input {} {
	    soap:body \
		[list use encoded namespace $url encodingStyle $ns(soap-enc)] {}
	  }
	  wsdl:output {} {
	    soap:body \
		[list use encoded namespace $url encodingStyle $ns(soap-enc)] {}
	  }
	}
      }
    }
  }
  
  RpcLiteral contains {
    Class Wsdl1.1Builder -instproc Abstract {obj} {
      [my info class] instvar ns styles
      my instvar url doc types style bpCompliant
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
		    -style $style \
		    -protocol ::xosoap::Soap]
	append argNodes [subst {
	  wsdl:part {
	    name $name type [$ar get xsType]
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
	set name [string range $r 0 [expr {$idx-1}]]
	set type [string range $r [expr {$idx+1}] end]
	set ar [::xorb::datatypes::AnyReader new \
		    -name $name \
		    -observer [self] \
		    -typecode $type \
		    -style $style \
		    -protocol ::xosoap::Soap] 
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
	  wsdl:input [list message "tns:[$obj name]Input"] {}
	  wsdl:output [list message "tns:[$obj name]Output"] {}
	}
      }

      # / / / / / / / / / / / / / / / / /
      # WS-I BP 1.0/1.1
      # R2705: Does not allow for
      # mixed styled bindings; compliance 
      # requires:
      # a-) to have a style attribute
      # for the entire soap:binding
      # scope
      # b-) no per-operation style settings
      # that would overrule according
      # to WSDL 1.1
      set soapOperationAttr(soapAction) ${url}/[$obj name]
      if {!$bpCompliant} {
	foreach {mStyle encStyle} $styles($style) break;
	set soapOperationAttr(style) $mStyle
      }
      
      set soapBodyAttr(use) literal
      # / / / / / / / / / / / / / / /
      # WS-I BP 1.0/1.1 R2717
      if {$bpCompliant} {
	set soapBodyAttr(namespace) $url
      }

      set binding [$doc getElementsByTagName "wsdl:binding"]
      $binding appendFromScript {
	wsdl:operation [list name [$obj name]] {
	  soap:operation [array get soapOperationAttr] {}
	  wsdl:input {} {
	    soap:body \
		[array get soapBodyAttr] {}
	  }
	  wsdl:output {} {
	    soap:body \
		[array get soapBodyAttr] {}
	  }
	}
      }
    }
  }
  
  DocumentLiteral contains {
    Class Wsdl1.1Builder -instproc Abstract {obj} {
      [my info class] instvar ns styles
      my instvar url doc types style bpCompliant
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
		    -style $style \
		    -protocol ::xosoap::Soap]
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
		    -style $style \
		    -protocol ::xosoap::Soap]
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
	  wsdl:input [list message "tns:[$obj name]Input"] {}
	  wsdl:output [list message "tns:[$obj name]Output"] {}
	}
      }
      
      # / / / / / / / / / / / / / / / / /
      # WS-I BP 1.0/1.1
      # R2705: Does not allow for
      # mixed styled bindings; compliance 
      # requires:
      # a-) to have a style attribute
      # for the entire soap:binding
      # scope
      # b-) no per-operation style settings
      # that would overrule according
      # to WSDL 1.1
      set soapOperationAttr(soapAction) ${url}/[$obj name]
      if {!$bpCompliant} {
	foreach {mStyle encStyle} $styles($style) break;
	set soapOperationAttr(style) $mStyle
      }
      
      set soapBodyAttr(use) literal
      # / / / / / / / / / / / / / / /
      # WS-I BP 1.0/1.1 R2717
      if {$bpCompliant} {
	set soapBodyAttr(namespace) $url
      }

      set binding [$doc getElementsByTagName "wsdl:binding"]
      $binding appendFromScript {
	wsdl:operation [list name [$obj name]] {
	  soap:operation [array get soapOperationAttr] {}
	  wsdl:input {} {
	    soap:body \
		[array get soapBodyAttr] {}
	  }
	  wsdl:output {} {
	    soap:body \
		[array get soapBodyAttr] {}
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
		     -parameter "marshaling_style" \
		     -package_id [::xo::cc set package_id]]
      #set style ::xosoap::DocumentLiteral
      set b [Wsdl1.1Builder new \
		 -contract $obj \
		 -style $style \
		 -volatile]
    } catch {error e} {
      #global errorInfo
      error [WsdlGenerationException new "Reason: '$e'"]
    }
    if {$b ne {}} {
      #ns_return 200 text/xml 
      return [$b xmlDoc]
    }
  }

  
  namespace export Wsdl1.1 Wsdl1.1Builder
  
  # # # # # # # # # # # 
  # # # # # # # # # # # 
  # # # # # # # # # # # 
  # # # # # # # # # # # 
  
}