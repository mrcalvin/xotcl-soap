ad_library {
  
  Support for XML Schema 1.0 'Built-in' Datatypes (simple, complex)
  Currently xosoap provides for compatibility with 
  'SOAPBuilders Interoperability Lab Round 2', base test suite;
  see http://www.whitemesa.com/interop/proposal2.html
  
  @author stefan.sobernig@wu-wien.ac.at
  @creation-date February 27, 2007
  @cvs-id $Id$
  
}



namespace eval ::xosoap::xsd {

  namespace import -force ::xorb::datatypes::*  
  namespace import -force ::xosoap::*

  # / / / / / / / / / / / / /
  # meta class for soap-related
  # primitives/composites

  ::xotcl::Class SoapPrimitive -slots {
    Attribute protocol -default {::xosoap::Soap}
  } -superclass MetaPrimitive
  
  ::xotcl::Class SoapComposite -superclass {
    SoapPrimitive MetaComposite
  }


  # / / / / / / / / / / / / /
  # primitive types/ decorators
  # for anything containers

  ::xotcl::Class XsAnything -superclass Anything
  XsAnything instproc parse {node} {
    my instvar __value__ isRoot__ isVoid__
    my log n=$node,type=[$node nodeType],xml=[$node asXML]
    # / / / / / / / / / / / / / / / / / /
    # TODO: handles cases of empty/'nilled' incoming
    # elements!!!!!!!! >> checkNode eq {}
    # e.g. <messageType/>
    set checkNode [$node firstChild]
    #set checkNode [expr {$initial?$node:[$node firstChild]}]
    if {$isRoot__ && $checkNode eq {}} {
      # XsVoid
      set isVoid__ true
    } elseif {$checkNode eq {} || [$checkNode nodeType] eq "TEXT_NODE"} {
      set __value__ [$node text]
    } elseif {[$checkNode nodeType] eq "ELEMENT_NODE"} {
      # / / / / / / / / / / / / / / /
      # look-ahead tests
      # 	1. return-element encoding flaviours: as leaf or 
      #	intermediary composite type
      #my log isRoot=$isRoot
      set lookAhead [$checkNode firstChild]
      if {$isRoot__ && $lookAhead eq {}} {
	# XsVoid
	set isVoid__ true
      } elseif {$isRoot__ && \
		    [$lookAhead nodeType] eq "TEXT_NODE"} {
	set __value__ [$checkNode text]
	set isRoot__ false
      } else {
	foreach c [$node childNodes] {
	  #my set $i [[self class] new -childof [self] -parse $c]
	  # my set __map__([$c nodeName]) $i
	  #incr i
	  set any [[self class] new \
		       -childof [self] \
		       -name__ [$c nodeName] \
		       -parse $c]
	  my add -parse true $any
	}
      }
    }
  }

  ::xotcl::Class XsSimple -superclass XsAnything
  XsSimple instproc expand=xsType {{reader {}}} {
    set xstype [string trimleft [namespace tail [my info class]] Xs]
    set xstype [string tolower $xstype 0 0]
    return xsd:$xstype
  }

  XsSimple instproc expand=xsDescription {reader} {
    my instvar name__
    #      $reader instvar observer
    # / / / / / / / / / / / /
    # Register element in general?
    #      if {[info exists observer]} {
    #	$observer instvar types
    # xsd:element {name $name type ${name}Type} {} is
    # added in document/literal style to types section!
    #	if {![info exists types($name)]} {
    #	  $observer set types($name) [subst {
    #	    xsd:element {name $name type [my expand=xsType $reader]} {}
    #	  }]
    #	}
    #     }
    # / / / / / / / / / / / /
    # Return element entry into compound?
    if {[$reader inCompound]} {
      return "xsd:element {name $name__ type [my expand=xsType $reader]} {}"
    }
  }
  
  XsSimple instproc marshal {document node soapElement} {
    # / / / / / / / / / / / / / / /
    # Provides for basic marshalling
    # into a text node to the current
    # element node. It is common
    # to all marshaling styles.
    my instvar isVoid__
    if {!$isVoid__ && [my isPrimitive]} {
      my instvar __value__ name__      
      $node appendChild \
	  [$document createTextNode $__value__]
    }
  }

  RpcEncoded contains {
    Class XsSimple -instproc marshal {document node soapElement}  {
      my instvar isVoid__
      if {!$isVoid__ && [my isPrimitive]} {
	$node setAttribute xsi:type [my expand=xsType]
      }
      next;# ::xosoap::xsd::XsSimple->marshal
    }
  }

  SoapPrimitive XsVoid -superclass XsSimple \
      -instproc validate args {
	my instvar __value__
	return [expr {$__value__ eq {}}]
      } -isSponsorFor ::xorb::datatypes::Void

  SoapPrimitive XsString -superclass XsSimple \
      -instproc validate args {
	my instvar __value__
	# TODO: change to a tcl-independent
	# regexp!
	return [regexp {^[\x9\xA\xD\x20-\xD7FF\xE000-\xFFFD\x10000-\x10FFFF]*$} $__value__]
      } -isSponsorFor ::xorb::datatypes::String
  
  SoapPrimitive XsBoolean -superclass XsSimple \
      -instproc validate args {
	my instvar __value__
	return [string is boolean $__value__]
      } -isSponsorFor ::xorb::datatypes::Boolean

  SoapPrimitive XsDecimal -superclass XsSimple \
      -instproc validate args {
	my instvar __value__
	return [regexp {^[+-]?(\d+(\.\d*)?|(\.\d+))$} $__value__]
	# return [regexp {^[+-]?\d+(\.\d*)?|(\.\d+)$} $value]
	# return [regexp {^[+-]?((\d+\.[0-9]+)|([0-9]+))$} $value]
	# return [regexp {^[+-]?((\d+\.\d*)|(\d+))$} $value]
      } -isSponsorFor ::xorb::datatypes::Float
  SoapPrimitive XsInteger -superclass XsDecimal \
      -instproc validate args {
	my instvar __value__
	set isDecimal [next];# Decimal->validate
	# / / / / / / / / / / / / / / /
	# We do not check for compatibility to
	# Tcl Integers that are limited to 32-bit
	# integers (and the respective value space:
	# +/-4294967295). Integer must be valid
	# decimals, without fractions and trailing
	# comma ...
	set isInteger [regexp {^[+-]?\d+$} $__value__]
	return [expr {$isDecimal && $isInteger}]
      }
  SoapPrimitive XsLong -superclass XsInteger \
      -instproc validate args {
	# Longs are the maximum capacity of Tcl
	# to represent (by expr wrapping)
	# catch takes care of all integers beyond or
	# below that value space
	my instvar __value__
	set isInteger [next];# XsInteger->validate
	if {[catch {
	  set r [expr {$isInteger && 9223372036854775807 >= abs($__value__)}]
	}]} { 
	  return 0 
	} else {
	  return $r
	}
      } 

  SoapPrimitive XsInt -superclass XsLong \
      -instproc validate args {
	my instvar __value__
	set isLong [next];# XsLong->validate
	return [expr {$isLong && 2147483647 >= abs($__value__)}]
      } -isSponsorFor ::xorb::datatypes::Integer

  SoapPrimitive XsDouble -superclass XsDecimal \
      -instproc validate args {
	# see http://www.w3.org/TR/xmlschema-2/#double
	# 1) check for lexical / notational form: decimal / sic
	# 2) value space check for sic elements: mantissa / exponent
	# (\+|-)?((\d+(.\d*)?)|(.\d+))((e|E)(\+|-)?\d+)?|-?INF|NaN
	my instvar __value__
	set isDecimal [next];# Decimal->validate
	if {[regexp -nocase {^-?inf|nan|0$} $__value__]} {
	  return 1
	} elseif {$isDecimal || \
		      [regexp {^[+-]?((\d+(.\d*)?)|(.\d+))(e|E)[+-]?\d+$} \
			   $__value__]} {
	  return [expr {pow(2,-1075) < abs($__value__) && abs($__value__) < pow(2,24)*pow(2,970)}]
	} else {
	  return 0
	}
      }
  SoapPrimitive XsFloat -superclass XsDecimal \
      -instproc validate args {
	# see http://www.w3.org/TR/xmlschema-2/#float
	# 1) check for lexical / notational form: decimal / sic
	# 2) value space check for sic elements: mantissa / exponent
	my instvar __value__
	set isDecimal [next];# Decimal->validate
	if {[regexp -nocase {^-?inf|nan|0$} $__value__]} {
	  return 1
	} elseif {$isDecimal || \
		      [regexp {^[+-]?((\d+(.\d*)?)|(.\d+))(e|E)[+-]?\d+$} \
			   $__value__]} {
	  return [expr {pow(2,-149) < abs($__value__) && abs($__value__) < pow(2,24)*pow(2,104)}]
	} else {
	  return 0
	}
      } -isSponsorFor ::xorb::datatypes::Float
  SoapPrimitive XsDate -superclass XsSimple  \
      -instproc validate args {
	my instvar __value__
	return [regexp {^-?([1-9]\d\d\d+|0\d\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])(Z|(\+|-)(0\d|1[0-4]):[0-5]\d)?$} $__value__]
	#return [regexp {^\d{4}-\d{2}-\d{2}(Z|[+-].+|$)$} $value]
      }
  SoapPrimitive XsTime -superclass XsSimple  \
      -instproc validate args {
	my instvar __value__
	return [regexp {^(([01]\d|2[0-3]):[0-5]\d:[0-5]\d(\.\d+)?|24:00:00(\.0+)?)(Z|(\+|-)(0\d|1[0-4]):[0-5]\d)?$} $__value__]
	#return [regexp {^\d{2}:\d{2}:\d{2}(Z|[+-].+|$)$} $value]
      }
  SoapPrimitive XsDateTime -superclass XsSimple \
      -instproc validate args {
	my instvar __value__
	return [regexp {^-?([1-9]\d\d\d+|0\d\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])T(([01]\d|2[0-3]):[0-5]\d:[0-5]\d(\.\d+)?|24:00:00(\.0+)?)(Z|(\+|-)(0\d|1[0-4]):[0-5]\d)?$} $__value__]
	#return [regexp {^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-].+|$)$} \
	    # $value]
      }
  SoapPrimitive XsBase64Binary -superclass XsSimple \
      -instproc validate args {
	my instvar __value__
	return [regexp {^((([A-Za-z0-9+/] ?){4})*(([A-Za-z0-9+/] ?){3}[A-Za-z0-9+/]|([A-Za-z0-9+/] ?){2}[AEIMQUYcgkosw048] ?=|[A-Za-z0-9+/] ?[AQgw] ?= ?=))?$} $__value__]
      }  

  SoapPrimitive XsHexBinary -superclass XsSimple \
      -instproc validate args {
	my instvar __value__
	return [string is xdigit $__value__]
      } 

  # / / / / / / / / / / / / / / /
  # Explicit support for xml schema
  # compound types
  # - XsCompound represents arbitrary
  # XS compound (complex) types and
  # therefore SOAP structs
  # - SoapArray represents SOAP arrays
  # being a specific subtype of 
  # XsCompounds

  ::xotcl::Class XsCompound -superclass XsAnything -slots {
    Attribute template
  } -instproc validate {reader} {
    my instvar template
    set template [$reader cast]
    # TODO: is validate for complex types
    # or structs needed? Handled by 'as' anyway!
    return true
  } -instproc unwrap args {
    my instvar template
    set template [string trimleft $template =]
    if {![my isclass $template]} {
      error "No such class '$template' declared/ available."
    }
    set anyObj [self]
    if {[my containsResultNode]} {
      set anyObj [my info children] 
    }
    if {$template eq {}} {
      error "type key specification '$typeKey' invalid."
    } else {
      my log TEMPLATE=[$template serialize]
      my log ANYOBJ=[$anyObj serialize]
      foreach s [$template info slots] {
	set type [$s anyType]
	set s [namespace tail $s]
	# / / / / / / / / / / / / /
	# provide for fallback
	# into ordinarical access
	# to nested any structures
	# provided that the template
	# comes with numerical accessors
	# and there is no equally
	# named variable available on
	# the current any object!
	$anyObj instvar __ordinary_map__
	if {![string is integer $s] && [$anyObj exists $s]} {
	  set any [$anyObj set $s]
	} elseif {[string is integer $s]} {
	  set any [lindex $__ordinary_map__ $s]
	} else {
	  error "Cannot resolve accessor '$s' to nested element in Anything object."
	}
	# / / / / / / / / / / / / /
	# TODO: better place to provide
	# for type key expansion?
	# if {[my isclass $type] && \
# 		![$type info superclass ::xorb::datatypes::Anything]} {
# 	  set type soapStruct=$type
# 	} else {

# 	  set constraints [string map {"(" " \{ " ")" " \} "} $type]
# 	  if {![info complete $constraints]} {
# 	    error "Array constraints not properly defined."
# 	  }
# 	  my log constraints=$constraints,l=[llength $constraints]
# 	  if {[llength $constraints] > 1} {
# 	    set type  soapArray=$type
# 	  }
# 	}
	my log any=$any,typeKey=$type
	set unwrapped [$any as -protocol ::xosoap::Soap $type]
	my log unwrapped=$unwrapped
	$anyObj set $s $unwrapped
      }
      #$anyObj mixin add $template
      $anyObj class $template
      return $anyObj
    }
  }

  
  XsCompound instproc marshal {document node soapElement} {
    my instvar isVoid__
    if {!$isVoid__} {
      # complex type
      my instvar __ordinary_map__
      foreach c $__ordinary_map__ {
	set cNode [$node appendChild \
		       [$document createElement [$c name__]]]
	$c marshal $document $cNode $soapElement
      }
    }
  }

  # / / / / / / / / / / / /
  # SoapStruct subclass of
  # XsCompound. Currently, it is a 
  # straight forward alias to
  # XsCompound. Its only purpose is
  # the explicit annotation, the logic
  # is implemented as XsCompound

  SoapComposite SoapStruct -superclass XsCompound \
      -isSponsorFor ::xorb::datatypes::Object
  SoapStruct instproc expand=xsType {reader} {
    $reader instvar cast
    return types:[namespace tail [$cast]]
  }

  RpcEncoded contains {
    Class SoapStruct -instproc expand=xsDescription {reader} {
      $reader instvar cast observer name
      set lname [namespace tail [$cast]]
      set members {}
      foreach s [$cast info slots] {
	my log member=$s,anyType=[$s anyType]
	set n [namespace tail $s]
	set ar [::xorb::datatypes::AnyReader new \
		    -name $n \
		    -typecode [$s anyType]\
		    -style [[self class] info parent] \
		    -observer $observer \
		    -inCompound true \
		    -protocol ::xosoap::Soap]
	append members "[$ar get xsDescription]\n"
      }
      $observer instvar types
      # xsd:element {name $name type ${name}Type} {} is
      # added in document/literal style to types section!
      if {![info exists types($lname)]} {
	$observer set types($lname) [subst {
	  xsd:complexType {name $lname} {
	    xsd:all {} {
	      $members
	    }
	  }
	}]
      }
      if {[$reader inCompound]} {
	return "xsd:element {name $lname type $lname} {}"
      }
    } -instproc marshal {document node soapElement} {
      my instvar isVoid__
      if {!$isVoid__} {
	my instvar template
	# / / / / / / / / / / /
	# TODO: Unify and merge with
	# expand=xsType!!!!
	set t [namespace tail $template]
	$node setAttribute xsi:type types:$t
      }
      next;#::xosoap::xsd::XsCompound->marshal
    }
  }



  RpcLiteral contains {
    Class SoapStruct -instproc expand=xsDescription {reader} {
      $reader instvar cast observer name
      set lname [namespace tail [$cast]]
      set members {}
      foreach s [$cast info slots] {
	my log member=$s,anyType=[$s anyType]
	set n [namespace tail $s]
	set ar [::xorb::datatypes::AnyReader new \
		    -name $n \
		    -typecode [$s anyType]\
		    -style [[self class] info parent] \
		    -observer $observer \
		    -inCompound true \
		    -protocol ::xosoap::Soap]
	append members "[$ar get xsDescription]\n"
      }
      $observer instvar types
      # xsd:element {name $name type ${name}Type} {} is
      # added in document/literal style to types section!
      if {![info exists types($lname)]} {
	$observer set types($lname) [subst {
	  xsd:complexType {name $lname} {
	    xsd:all {} {
	      $members
	    }
	  }
	}]
      }
      if {[$reader inCompound]} {
	return "xsd:element {name $lname type $lname} {}"
      }
    }
  }

  DocumentLiteral contains {
    Class SoapStruct -instproc expand=xsDescription {reader} {
      $reader instvar cast observer name
      set castName [namespace tail [$cast]]
      set members {}
      foreach s [$cast info slots] {
	set n [namespace tail $s]
	set ar [::xorb::datatypes::AnyReader new \
		    -name $n \
		    -typecode [$s anyType] \
		    -style [[self class] info parent] \
		    -observer $observer \
		    -inCompound true \
		    -protocol ::xosoap::Soap] 
	append members "[$ar get xsDescription]\n"
      }
      $observer instvar types
      # xsd:element {name $name type ${name}Type} {} is
      # added in document/literal style to types section!
      my log NAME($castName)=MEMBERS=$members
      if {![info exists types($castName)]} {
	# -1- if element referred from message part,
	# serialise into nested/ embedded complex type
	# -2- if referred from type attribute within
	# schema section, make it a new global type
	# declaration
	# This is semantically more correct, in the sense
	# of Document/Literal. It also provides for
	# compatibility to frameworks, such as Axis,
	# that can hardly deal with multiple similarily
	# named (only difference through minors/majors etc.), 
	# reified types ...
	if {[$reader inCompound]} {
	  # -2-
	  set t [subst {
	    xsd:complexType {name ${castName}} {
	      xsd:all {} {
		$members
	      }
	    }
	  }]
	} else {
	 # -1-
	  set t [subst {
	    xsd:element {name $castName} {
	      xsd:complexType {} {
		xsd:all {} {
		  $members
		}
	      }
	    }
	  }]
	}
	$observer set types($castName) $t
      }
      # return type reference to the global type definition!
      if {[$reader inCompound]} {
	return "xsd:element {name $name type types:${castName}} {}"
      }
    }
  }
  SoapStruct instproc parseObject {reader object} {
    my instvar template
    set template [$reader cast]
    # / / / / / / / / / / / / / /
    # TODO: find a more efficient
    # way of expanding any types 
    # in compounds than looping
   #  foreach s [$any info slots] {
#       $s instvar anyType
#       if {[my isclass $anyType] &&\
# 	      ![$anyType info superclass ::xorb::datatypes::Anything]} {
# 	$s anyType soapStruct=$anyType
#       } else {

# 	set constraints [string map {"(" " \{ " ")" " \} "} $anyType]
# 	if {![info complete $constraints]} {
# 	  error "Array constraints not properly defined."
# 	}
# 	if {[llength $constraints] > 1} {
# 	  set anyType soapArray=$anyType
# 	}
#       }
#     }
    next
  }
  # / / / / / / / / / / / /
  # SoapArray + ArrayBuilder
  # as derivations of XsCompound

  ::xotcl::Class ArrayBuilder -slots {
    Attribute type -default ::xosoap::xsd::XsAnything
    Attribute size
    Attribute tagName -default "member"
  } -superclass ::xotcl::Class
  
  ArrayBuilder instproc init args {
    my instvar type size tagName
    # / / / / / / / / / / / / / / / /
    # TODO recast as XS types or not!
    # would interfere with current logic
    # in Checkoption+Uplift!
    # my superclass ::xosoap::xsd::SoapArray

    for {set i 0} {$i <= [expr {$size -1}]} {incr i} {
      append cmds [subst {
	::xorb::datatypes::AnyAttribute $i -tagName $tagName -anyType $type 
      }] 
    }
    my slots $cmds
  }

  SoapComposite SoapArray -superclass XsCompound -slots {
    Attribute tagName -default "member"
  }

  RpcEncoded contains {
    Class SoapArray -instproc expand=xsDescription {reader} {
      # / / / / / / / / / / / / / / / / 
      # for rpc/encoded, we follow
      # the original wsdl 1.1 guideline
      # on how to describe and serialise
      # array types.
      $reader instvar cast suffix observer
      my instvar name__ tagName
      set ar [::xorb::datatypes::AnyReader new \
		  -typecode $cast \
		  -observer $observer \
		  -style [[self class] info parent] \
		  -observer $observer \
		  -inCompound true \
		  -protocol ::xosoap::Soap]
      $observer instvar types
      set fulltype [$ar get xsType]
      set t [string map {types: "" xsd: ""} $fulltype]
      set t [string toupper $t 0 0]

      if {![info exists types(ArrayOf$t)]} {
	$observer set types(ArrayOf$t) [subst -nocommands {
	  xsd:complexType {name ArrayOf$t} {
	    xsd:complexContent {} {
	      restriction {base SOAP-ENC:Array} {
		attribute {ref SOAP-ENC:arrayType wsdl:arrayType $fulltype[]} {}
	      }
	    }
	  }
	}]
      }
    } -instproc expand=xsType {reader} {
      $reader instvar suffix cast
      set ar [::xorb::datatypes::AnyReader new \
		  -style [[self class] info parent]\
		  -typecode $cast \
		  -protocol ::xosoap::Soap]
      #set idx [string map {"<" "[" ">" "]"} $suffix]
      set t [string map {types: "" xsd: ""} [$ar get xsType]]
      set t [string toupper $t 0 0]
      return types:ArrayOf$t
      #my instvar name
      #return tns:${name}Type
      #     $reader instvar cast suffix
      #     set idx [string map {"<" "[" ">" "]"} $suffix]
      #     set ar [AnyReader new -typecode $cast]
      #     return [$ar get xsType]$idx
    } -instproc marshal {document node soapElement} {
      # / / / / / / / / / / / / / /
      # Enforce default soap array:
      # Type-wise SOAP encoding!
      my instvar template
      $template instvar type size
      set ar [::xorb::datatypes::AnyReader new \
		  -style [[self class] info parent]\
		  -typecode $type \
		  -protocol ::xosoap::Soap]
      set xstype [$ar get xsType]
      $node setAttribute xsi:type "SOAP-ENC:Array"
      $node setAttribute SOAP-ENC:arrayType "$xstype\[$size\]"
      next $document $node $soapElement;# XsCompound->marshal
    }
  }

  RpcLiteral contains {
    Class SoapArray -instproc expand=xsDescription {reader} {
      # / / / / / / / / / / / / / / / / / / / / / / /
      # we follow the WS-I Basic profile recommendation
      # for the XS description of SOAP arrays
      # see Section 5.2.3, e.g.
      # http://www.ws-i.org/Profiles/BasicProfile-1.0-2004-04-16.html#refinement16556272
      $reader instvar cast suffix observer
      my instvar name__ tagName
      #set idx [string map {"<" "[" ">" "]"} $suffix]
      #set idx [string map {"<" "" ">" " "} $suffix]
      #set idx [lindex $idx end]
      set ar [::xorb::datatypes::AnyReader new \
		  -typecode $cast \
		  -observer $observer \
		  -style [[self class] info parent] \
		  -observer $observer \
		  -inCompound true \
		  -protocol ::xosoap::Soap]
      #return [$ar get flag]$idx
      # xsd:element {name $name type ${name}Type} {} is
      # added in document/literal style to types section!
      $observer instvar types
      set t [string map {types: "" xsd: ""} [$ar get xsType]]
      set t [string toupper $t 0 0]
      if {![info exists types(ArrayOf$t)]} {
	$observer set types(ArrayOf$t) [subst {
	  xsd:complexType {name ArrayOf${t}} {
	    xsd:sequence {} {
	      xsd:element {
		name $tagName 
		type [$ar get xsType] 
		minOccurs 0 
		maxOccurs unbounded} {}
	    }
	  }
	}]
      }
    } -instproc expand=xsType {reader} {
      $reader instvar suffix cast
      set ar [::xorb::datatypes::AnyReader new \
		  -style [[self class] info parent]\
		  -typecode $cast \
		  -protocol ::xosoap::Soap]
      #set idx [string map {"<" "[" ">" "]"} $suffix]
      set t [string map {types: "" xsd: ""} [$ar get xsType]]
      set t [string toupper $t 0 0]
      return types:ArrayOf$t
      #my instvar name
      #return tns:${name}Type
      #     $reader instvar cast suffix
      #     set idx [string map {"<" "[" ">" "]"} $suffix]
      #     set ar [AnyReader new -typecode $cast]
      #     return [$ar get xsType]$idx
    } -instproc marshal {document node soapElement} {
      # / / / / / / / / / / / / / /
      # Enforce default soap array
      # encoding (appropriate annotation)
      # Currently, we stick with the attribute-wise,
      # XS-based annotation!
      # e.g.: 
      my instvar template
      $template instvar type size
      set ar [::xorb::datatypes::AnyReader new \
		  -style [[self class] info parent]\
		  -typecode $type]
      set xstype [$ar get xsType]
      # / / / / / / / / / / / / / /
      # Introduce specifc serialisation
      # rules for soap structs
      #  if {[my isclass $type] &&\
	  # 	    ![$type info superclass ::xorb::datatypes::Anything]} {
      #       set xstype "m:SoapStruct"
      #     } else {
      #       set xstype [string trimleft [namespace tail $type] Xs]
      #       set xstype "xsd:[string tolower $xstype 0 0]"
      #     }
      
      #$node setAttribute xsi:type "SOAP-ENC:Array"
      #$node setAttribute SOAP-ENC:arrayType "$xstype\[$size\]"
      next $document $node $soapElement;# XsCompound->marshal
    }
  }
  DocumentLiteral contains {
    Class SoapArray -instproc expand=xsDescription {reader} {
      # / / / / / / / / / / / / / / / / / / / / / / /
      # we follow the WS-I Basic profile recommendation
      # for the XS description of SOAP arrays
      # see Section 5.2.3, e.g.
      # http://www.ws-i.org/Profiles/BasicProfile-1.0-2004-04-16.html#refinement16556272
      $reader instvar cast suffix observer
      my instvar name__ tagName
      #set idx [string map {"<" "[" ">" "]"} $suffix]
      #set idx [string map {"<" "" ">" " "} $suffix]
      #set idx [lindex $idx end]
      set ar [::xorb::datatypes::AnyReader new \
		  -typecode $cast \
		  -observer $observer \
		  -style [[self class] info parent] \
		  -observer $observer \
		  -inCompound true]
      #return [$ar get flag]$idx
      # xsd:element {name $name type ${name}Type} {} is
      # added in document/literal style to types section!
      $observer instvar types
      set t [string map {types: "" xsd: ""} [$ar get xsType]]
      set t [string toupper $t 0 0]
      if {![info exists types(ArrayOf$t)]} {
	$observer set types(ArrayOf$t) [subst {
	  xsd:element {name $name type types:ArrayOf${t}} {}
	  xsd:complexType {name ArrayOf${t}} {
	    xsd:sequence {} {
	      xsd:element {
		name $tagName 
		type [$ar get xsType] 
		minOccurs 0 
		maxOccurs unbounded} {}
	    }
	  }
	}]
      }
    }
  }
  SoapArray instproc enbrace {in} {
    #return [return [string map {"[" " " "]" ""} $in]]
    return [string map {"(" " \{ " ")" " \} "} $in]
  }
  SoapArray instproc validate {reader} {
    my instvar template __ordinary_map__
    #    foreach spec $args break
    #set constraints [my enbrace $spec]
    #if {![info complete $constraints]} {
    #  error "Array constraints not properly defined."
    #}
    #set last [string trim [lindex $constraints end]]
    #set allowedType [string trim [lindex $constraints 0]]
    #set allowedType [Anything getTypeClass [string trimleft $allowedType =]]
    # / / / / / / / / / / / / / / /
    # expand nested types: 1) nested struct specs
#    if {$allowedType ne {} && [my isclass $allowedType] \
#	    && ![$allowedType info superclass ::xorb::datatypes::Anything]} {
      # default to soapStructs
#      set allowedType soapStruct=$allowedType
 #   } elseif {[llength $constraints] > 2} {
      # / / / / / / / / / / / / / / /







      # TODO expand nested types: 2) nested array specs
  #    set allowedType soapArray=$allowedType
   # } 
    set last [lindex [string map {"<" "" ">" " "} [$reader suffix]] end]
    set template [ArrayBuilder new -type [$reader unbrace [$reader cast]] \
		      -size $last]
    if {[llength $__ordinary_map__] > [$template size]} {
      return false
    } else {
      return true
    }
  }
  
  SoapArray instproc parseObject {reader object} {
    # 1)
    my instvar template
    #set constraints [my enbrace $class]
    #if {![info complete $constraints]} {
    #  error "Array constraints not properly defined."
    #}
    #set last [string trim [lindex $constraints end]]
    #set allowedType [Anything getTypeClass [string trim [lindex $constraints 0]]]
    #if {$allowedType ne {} && [my isclass $allowedType] \
	#    && ![$allowedType info superclass ::xorb::datatypes::Anything]} {
      # default to soapStructs
    #  set allowedType soapStruct=$allowedType
    #}
    #set ar [AnyReader new -typecode [$reader cast]]
    set last [lindex [string map {"<" "" ">" " "} [$reader suffix]] end]
    set template [ArrayBuilder new -type [$reader unbrace [$reader cast]] \
		      -size $last]
    my log CLASS=[$reader any],cast=[$template serialize],size=$last
    $reader cast $template
    next $reader $object;# Anything->parseObject




  }
  namespace export XsString XsInteger XsDouble\
      XsFloat XsDecimal XsDateTime XsDate XsTime XsBase64Binary XsHexBinary\
      XsBoolean SoapArray SoapStruct ArrayBuilder XsLong XsInt

  # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # #

  # ::xotcl::Class ComplexType -superclass ::xotcl::Class
#   ComplexType instproc slots args {
#     if {![[self class] exists nested]} {
#       [self class] set nested 0
#     } else {
#       [self class] incr nested
#     }
#     ::xotcl::Object instmixin add [self class]::SlotManager
#     next
#     if {[[self class] set nested]==0 && \
# 	    [::xotcl::Object info instmixin [self class]::SlotManager] ne {}} {
#       ::xotcl::Object instmixin delete [self class]::SlotManager
#       [self class] unset nested
#     } else {
#       [self class] incr nested -1
#     }
#   }
#   ::xotcl::Class ComplexType::SlotManager -instproc init {
#     {cmds ""} 
#     {member ""}
#   } {
#     if {[[my info class] istype ::xosoap::xsd::ComplexType]} {
#       set domain [lindex [regexp -inline \
# 			      {^(.*)::slot::[^:]+$} [::xotcl::self]] 1]
      
#       $domain slots [list Attribute [namespace tail [self]] \
# 			 -default "\[[my info class] new\]" -type [my info class]]
      
#     } elseif {[my istype ::xosoap::xsd::Struct]} {
#       # nested declaration
#       set domain [my info parent]
#       $domain slots [list Attribute $member \
# 			 -default "\[[self] new\]" \
# 			 -type [self]]
#       next $cmds
      
#     } elseif {[my istype ::xosoap::xsd::Array]} {
#       set domain [my info parent]
#       set c [list Attribute [namespace tail [self]] \
# 		 -default "\[[self] new\]"\
# 		 -type [self]]
#       $domain slots $c 
#       next
#     } else {
#       next
#     }
#   } -instproc create {objname args} {
#     set co [self callingobject]
    
#     # case 1: calling object is array 
#     # (rewrite objnames, but leave them RELATIVE)
#     if { [$co istype "::xosoap::xsd::Array"] && (
# 	[my info superclass [[self class] info parent]] || \
# 	    [my info superclass ::xosoap::xsd::SimpleType] || \
# 	    [my istype [[self class] info parent]] )
#        } {
#       $co instvar counter
#       set objname [expr {[info exists counter]?\
# 			     $counter:[set counter 0]}]
#       incr counter
#     }
    
#     # case 2: nested declarations? (make ABSOLUTE names)
#     if {[my info superclass [[self class] info parent]]} {
#       if {[self] eq "::xosoap::xsd::Struct" && \
# 	      ![$co istype ::xosoap::xsd::Struct]} {
# 	error {
# 	  Inner struct declarations are not allowed 
# 	  in complex types other than (outer) structs.
# 	}
#       }
#       if {[string first :: $objname] == -1} {
# 	set objname ${co}::$objname
#       } else {
# 	error "Members to complex types must have explicitly declared labels."
#       }
#     }
#     eval next $objname $args
#   }
  
#   ComplexType instproc init {{cmds ""}} {
#     if {$cmds ne {}} {
#       my slots $cmds
#     }
#     next
#   }
#   ::xotcl::Class Struct -superclass ComplexType

#   ::xotcl::Class IArray
#   IArray instproc asList {} {
#     set r [list]
#     foreach s [[my info class] info slots] {
#       if {[my exists [$s name]]} {
# 	lappend r [my [$s name]]
#       }
#     }
#     return $r
#     # return slot objects in list, for looping etc.
#   }
#   ::xotcl::Class Array -superclass ComplexType -parameter {
#     type
#     size
#   }
#   Array instproc slots args {
#     next;# ComplexType->slots
#     # set size if not already done explicitly
#   }
#   Array instproc init {{cmds {}}} {
#     if {[my exists type] && [my exists size] && $cmds eq {}} {
#       my instvar type size
#       for {set x 0} {$x<$size} {incr x} {
# 	append cmds "$type create $x\n" 
#       }
#       eval my slots [list $cmds]
#       my superclass add IArray
#     } else {
#       eval my slots [list $cmds]
#       my superclass add IArray
#     }
#   }
   
  
#   ::xotcl::Class MetaType -superclass ::xotcl::Class
#   # MetaType proc getAcsDatatypes {} {
# #     my instvar acsDatatypes
# #     if {![info exists acsDatatypes]} {
# #       set acsDatatypes [db_list get_acs_datatypes {
# # 	select datatype from acs_datatypes;
# #       }]
# #       return $acsDatatypes
# #     }
# #   }
# #   MetaType proc datatypeExists {label} {
# #     set dts [my getAcsDataTypes] 
# #     return [expr {[lsearch -exact $dts $label] != -1}]
# #   }
#   MetaType instproc validate {value} {
#     return [[[self] new -volatile] validate $value]
#   }
#   # MetaType instproc init args {
# #     set l [string tolower [namespace tail [self]] 0 0]
# #     if {![[self class] datatypeExists $l]} {
# #       # do insert + list update
# #     }
# #   }
  
  
#   ::xotcl::Class SimpleType -superclass ::xotcl::Attribute
#   SimpleType instproc init args {
#     my type "my validate"
#     next
#   } 
#   MetaType String -superclass SimpleType \
#       -instproc validate {value} {
# 	return [string is print $value]
#       }
#   MetaType Boolean -superclass SimpleType \
#       -instproc validate {value} {
# 	return [string is boolean $value]
#       }
#   MetaType Decimal -superclass SimpleType \
#       -instproc validate {value} {
# 	return [regexp {^[+-]?(\d+(\.\d*)?|(\.\d+))$} $value]
# 	# return [regexp {^[+-]?\d+(\.\d*)?|(\.\d+)$} $value]
# 	# return [regexp {^[+-]?((\d+\.[0-9]+)|([0-9]+))$} $value]
# 	# return [regexp {^[+-]?((\d+\.\d*)|(\d+))$} $value]
#       }
  
#   MetaType Integer -superclass Decimal \
#       -instproc validate {value} {
# 	set isDecimal [next];# Decimal->validate
# 	return [expr {$isDecimal && [string is integer $value]}]
#       }
  
#   MetaType Double -superclass Decimal \
#       -instproc validate {value} {
# 	# see http://www.w3.org/TR/xmlschema-2/#double
# 	# 1) check for lexical / notational form: decimal / sic
# 	# 2) value space check for sic elements: mantissa / exponent
# 	# (\+|-)?((\d+(.\d*)?)|(.\d+))((e|E)(\+|-)?\d+)?|-?INF|NaN
# 	set isDecimal [next];# Decimal->validate
# 	if {[regexp -nocase {^-?inf|nan|0$} $value]} {
# 	  return 1
# 	} elseif {$isDecimal || \
# 		      [regexp {^[+-]?((\d+(.\d*)?)|(.\d+))(e|E)[+-]?\d+$} \
# 			   $value]} {
# 	  return [expr {pow(2,-1075) < abs($value) && abs($value) < pow(2,24)*pow(2,970)}]
# 	} else {
# 	  return 0
# 	}
#       }
#   MetaType Float -superclass Decimal \
#       -instproc validate {value} {
# 	# see http://www.w3.org/TR/xmlschema-2/#float
# 	# 1) check for lexical / notational form: decimal / sic
# 	# 2) value space check for sic elements: mantissa / exponent
# 	set isDecimal [next];# Decimal->validate
# 	if {[regexp -nocase {^-?inf|nan|0$} $value]} {
# 	  return 1
# 	} elseif {$isDecimal || \
# 		      [regexp {^[+-]?((\d+(.\d*)?)|(.\d+))(e|E)[+-]?\d+$} \
# 			   $value]} {
# 	  return [expr {pow(2,-149) < abs($value) && abs($value) < pow(2,24)*pow(2,104)}]
# 	} else {
# 	  return 0
# 	}
#       } 
#   MetaType Date -superclass SimpleType  \
#       -instproc validate {value} {
# 	return [regexp {^-?([1-9]\d\d\d+|0\d\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])(Z|(\+|-)(0\d|1[0-4]):[0-5]\d)?$} $value]
# 	#return [regexp {^\d{4}-\d{2}-\d{2}(Z|[+-].+|$)$} $value]
#       }
#   MetaType Time -superclass SimpleType  \
#       -instproc validate {value} {
# 	return [regexp {^(([01]\d|2[0-3]):[0-5]\d:[0-5]\d(\.\d+)?|24:00:00(\.0+)?)(Z|(\+|-)(0\d|1[0-4]):[0-5]\d)?$} $value]
# 	#return [regexp {^\d{2}:\d{2}:\d{2}(Z|[+-].+|$)$} $value]
#       }
#   MetaType DateTime -superclass SimpleType \
#       -instproc validate {value} {
# 	return [regexp {^-?([1-9]\d\d\d+|0\d\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])T(([01]\d|2[0-3]):[0-5]\d:[0-5]\d(\.\d+)?|24:00:00(\.0+)?)(Z|(\+|-)(0\d|1[0-4]):[0-5]\d)?$} $value]
# 	#return [regexp {^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-].+|$)$} \
# 	    # $value]
#       }
#   MetaType Base64Binary -superclass SimpleType \
#       -instproc validate {value} {
# 	return [regexp {^((([A-Za-z0-9+/] ?){4})*(([A-Za-z0-9+/] ?){3}[A-Za-z0-9+/]|([A-Za-z0-9+/] ?){2}[AEIMQUYcgkosw048] ?=|[A-Za-z0-9+/] ?[AQgw] ?= ?=))?$} $value]
#       }
  
#   MetaType HexBinary -superclass SimpleType \
#       -instproc validate {value} {
# 	return [string is xdigit $value]
#       }


#   namespace export Struct Array String Integer Double\
#       Float Decimal DateTime Date Time Base64Binary HexBinary\
#       Boolean
}
