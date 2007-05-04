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
  # / / / / / / / / / / / / /
  # primitive types/ decorators
  # for anything containers

  ::xotcl::Class XsAnything -superclass Anything
  XsAnything instproc parse {node} {
    my instvar __value__ isRoot isVoid
    #my log n=$node,type=[$node nodeType],xml=[$node asXML]
    set checkNode [$node firstChild]
    #set checkNode [expr {$initial?$node:[$node firstChild]}]
    if {$isRoot && $checkNode eq {}} {
      # XsVoid
      set isVoid true
    } elseif {[$checkNode nodeType] eq "TEXT_NODE"} {
      set __value__ [$node text]
    } elseif {[$checkNode nodeType] eq "ELEMENT_NODE"} {
      # / / / / / / / / / / / / / / /
      # look-ahead tests
      # 	1. return-element encoding flaviours: as leaf or 
      #	intermediary composite type
      #my log isRoot=$isRoot
      if {$isRoot && [[$checkNode firstChild] nodeType] eq "TEXT_NODE"} {
	set __value__ [$checkNode text]
	set isRoot false
      } else {
	puts children=[$node childNodes]
	foreach c [$node childNodes] {
	  #my set $i [[self class] new -childof [self] -parse $c]
	 # my set __map__([$c nodeName]) $i
	  #incr i
	  set any [[self class] new \
		       -childof [self] \
		       -name [$c nodeName] \
		       -parse $c]
	  my add -parse $any
	}
      }
    }
  }

  ::xotcl::Class XsSimple -superclass XsAnything
  
  
  XsSimple instproc marshal {document node soapElement} {
    # / / / / / / / / / / / / / / /
    # currently provides for XS-like
    # streaming/ annotation of anys
    my instvar isVoid
    if {!$isVoid && [my isPrimitive]} {
      my instvar __value__ name
      # / / / / / / / / / / / / / / / / /
      # TODO: get xsd key from actual objects
      # abstract from the xotcl-soap case here
      # no simple trimleft of prefix 'Xs'
      set xstype [string trimleft [namespace tail [my info class]] Xs]
      set xstype [string tolower $xstype 0 0]
     #  if {[$soapElement istype ::xosoap::marshaller::SoapBodyResponse] && \
# 	      ![info exists name]} {
# 	set name [string map {Response Return} [$soapElement elementName]]
#       }
      # set anyNode [$node appendChild \
# 			  [$document createElement $name]]
      $node setAttribute xsi:type "xsd:$xstype"
      $node appendChild \
	  [$document createTextNode $__value__]
    }
  }
  
  MetaAny XsVoid -superclass XsSimple \
      -instproc validate args {
	my instvar __value__
	return [expr {$__value__ eq {}}]
      }

  MetaAny XsString -superclass XsSimple \
      -instproc validate args {
	my instvar __value__
	return [string is print $__value__]
      }
  MetaAny XsBoolean -superclass XsSimple \
      -instproc validate args {
	my instvar __value__
	return [string is boolean $__value__]
      }
  MetaAny XsDecimal -superclass XsSimple \
      -instproc validate args {
	my instvar __value__
	return [regexp {^[+-]?(\d+(\.\d*)?|(\.\d+))$} $__value__]
	# return [regexp {^[+-]?\d+(\.\d*)?|(\.\d+)$} $value]
	# return [regexp {^[+-]?((\d+\.[0-9]+)|([0-9]+))$} $value]
	# return [regexp {^[+-]?((\d+\.\d*)|(\d+))$} $value]
      }
  
  MetaAny XsInteger -superclass XsDecimal \
      -instproc validate args {
	my instvar __value__
	set isDecimal [next];# Decimal->validate
	return [expr {$isDecimal && [string is integer $__value__]}]
      }
  
  MetaAny XsDouble -superclass XsDecimal \
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
  MetaAny XsFloat -superclass XsDecimal \
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
      } 
  MetaAny XsDate -superclass XsSimple  \
      -instproc validate args {
	my instvar __value__
	return [regexp {^-?([1-9]\d\d\d+|0\d\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])(Z|(\+|-)(0\d|1[0-4]):[0-5]\d)?$} $__value__]
	#return [regexp {^\d{4}-\d{2}-\d{2}(Z|[+-].+|$)$} $value]
      }
  MetaAny XsTime -superclass XsSimple  \
      -instproc validate args {
	my instvar __value__
	return [regexp {^(([01]\d|2[0-3]):[0-5]\d:[0-5]\d(\.\d+)?|24:00:00(\.0+)?)(Z|(\+|-)(0\d|1[0-4]):[0-5]\d)?$} $__value__]
	#return [regexp {^\d{2}:\d{2}:\d{2}(Z|[+-].+|$)$} $value]
      }
  MetaAny XsDateTime -superclass XsSimple \
      -instproc validate args {
	my instvar __value__
	return [regexp {^-?([1-9]\d\d\d+|0\d\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])T(([01]\d|2[0-3]):[0-5]\d:[0-5]\d(\.\d+)?|24:00:00(\.0+)?)(Z|(\+|-)(0\d|1[0-4]):[0-5]\d)?$} $__value__]
	#return [regexp {^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-].+|$)$} \
	    # $value]
      }
  MetaAny XsBase64Binary -superclass XsSimple \
      -instproc validate args {
	my instvar __value__
	return [regexp {^((([A-Za-z0-9+/] ?){4})*(([A-Za-z0-9+/] ?){3}[A-Za-z0-9+/]|([A-Za-z0-9+/] ?){2}[AEIMQUYcgkosw048] ?=|[A-Za-z0-9+/] ?[AQgw] ?= ?=))?$} $__value__]
      }
  
  MetaAny XsHexBinary -superclass XsSimple \
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
  } -instproc validate args {
    my instvar template
    foreach template $args break
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
	my log any=$any,typeKey=$type
	set unwrapped [$any as $type]
	my log unwrapped=$unwrapped
	$anyObj set $s [$any as $type]
      }
      #$anyObj mixin add $template
      $anyObj class $template
      return $anyObj
    }
  }

  
  XsCompound instproc marshal {document node soapElement} {
    my instvar isVoid
    if {!$isVoid} {
      # complex type
      my instvar __ordinary_map__
      foreach c $__ordinary_map__ {
	set cNode [$node appendChild \
		       [$document createElement [$c name]]]
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

  MetaAny SoapStruct -superclass XsCompound

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

  MetaAny SoapArray -superclass XsCompound
  SoapArray instproc enbrace {in} {
    #return [return [string map {"[" " " "]" ""} $in]]
    return [string map {"(" " \{ " ")" " \} "} $in]
  }
  SoapArray instproc validate args {
    my instvar template __ordinary_map__
    foreach spec $args break
    set constraints [my enbrace $spec]
    if {![info complete $constraints]} {
      error "Array constraints not properly defined."
    }
    set last [string trim [lindex $constraints end]]
    set allowedType [string trim [lindex $constraints 0]]
    set allowedType [Anything getTypeClass [string trimleft $allowedType =]]
    set template [ArrayBuilder new -type $allowedType -size $last]
    if {[llength $__ordinary_map__] > [$template size]} {
      return false
    } else {
      return true
    }
  }
  SoapArray instproc marshal {document node soapElement} {
    # / / / / / / / / / / / / / /
    # Enforce default soap array
    # encoding (appropriate annotation)
    # Currently, we stick with the attribute-wise,
    # XS-based annotation!
    # e.g.: 
    # <... xsi:type="SOAP-ENC:Array" SOAP-ENC:arrayType="xsd:string[2]" ...>
    my instvar template
    $template instvar type size
     set xstype [string trimleft [namespace tail $type] Xs]
      set xstype [string tolower $xstype 0 0]
    $node setAttribute xsi:type "SOAP-ENC:Array"
    $node setAttribute SOAP-ENC:arrayType "xsd:$xstype\[$size\]"
    next $document $node $soapElement;# XsCompound->marshal
  }
  SoapArray instproc parseObject {class object} {
    # 1)
    my instvar template
    set constraints [my enbrace $class]
    if {![info complete $constraints]} {
      error "Array constraints not properly defined."
    }
    set last [string trim [lindex $constraints end]]
    set allowedType [Anything getTypeClass [string trim [lindex $constraints 0]]]
    if {$allowedType ne {} && [my isclass $allowedType] \
	    && ![$allowedType info superclass ::xorb::datatypes::Anything]} {
      # default to soapStructs
      set allowedType soapStruct=$allowedType
    }
    my log CLASS=$allowedType,object=[$object serialize],size=$last
    set template [ArrayBuilder new -type $allowedType -size $last]
    next $template $object;# Anything->parseObject
  }
  
  namespace export XsString XsInteger XsDouble\
      XsFloat XsDecimal XsDateTime XsDate XsTime XsBase64Binary XsHexBinary\
      XsBoolean SoapArray SoapStruct ArrayBuilder

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
