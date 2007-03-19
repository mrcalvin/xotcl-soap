ad_library {
  
  Support for XML Schema 1.0 'Built-in' Datatypes (simple, complex)
  Currently xosoap provides for compatibility with 
  'SOAPBuilders Interoperability Lab Round 2', base test suite;
  see http://www.whitemesa.com/interop/proposal2.html
  
  @author stefan.sobernig@wu-wien.ac.at
  @creation-date February 27, 2007
  @cvs-id $Id: xorb-procs.tcl 17 2006-09-26 14:34:40Z ssoberni $
  
}

namespace eval ::xosoap::xsd {

  ::xotcl::Class ComplexType -superclass ::xotcl::Class
  ComplexType instproc slots args {
    if {![[self class] exists nested]} {
      [self class] set nested 0
    } else {
      [self class] incr nested
    }
    ::xotcl::Object instmixin add [self class]::SlotManager
    next
    if {[[self class] set nested]==0 && \
	    [::xotcl::Object info instmixin [self class]::SlotManager] ne {}} {
      ::xotcl::Object instmixin delete [self class]::SlotManager
      [self class] unset nested
    } else {
      [self class] incr nested -1
    }
  }
  ::xotcl::Class ComplexType::SlotManager -instproc init {
    {cmds ""} 
    {member ""}
  } {
    if {[[my info class] istype ::xosoap::xsd::ComplexType]} {
      set domain [lindex [regexp -inline \
			      {^(.*)::slot::[^:]+$} [::xotcl::self]] 1]
      
      $domain slots [list Attribute [namespace tail [self]] \
			 -default "\[[my info class] new\]" -type [my info class]]
      
    } elseif {[my istype ::xosoap::xsd::Struct]} {
      # nested declaration
      set domain [my info parent]
      $domain slots [list Attribute $member \
			 -default "\[[self] new\]" \
			 -type [self]]
      next $cmds
      
    } elseif {[my istype ::xosoap::xsd::Array]} {
      set domain [my info parent]
      set c [list Attribute [namespace tail [self]] \
		 -default "\[[self] new\]"\
		 -type [self]]
      $domain slots $c 
      next
    } else {
      next
    }
  } -instproc create {objname args} {
    set co [self callingobject]
    
    # case 1: calling object is array 
    # (rewrite objnames, but leave them RELATIVE)
    if { [$co istype "::xosoap::xsd::Array"] && (
	[my info superclass [[self class] info parent]] || \
	    [my info superclass ::xosoap::xsd::SimpleType] || \
	    [my istype [[self class] info parent]] )
       } {
      $co instvar counter
      set objname [expr {[info exists counter]?\
			     $counter:[set counter 0]}]
      incr counter
    }
    
    # case 2: nested declarations? (make ABSOLUTE names)
    if {[my info superclass [[self class] info parent]]} {
      if {[self] eq "::xosoap::xsd::Struct" && \
	      ![$co istype ::xosoap::xsd::Struct]} {
	error {
	  Inner struct declarations are not allowed 
	  in complex types other than (outer) structs.
	}
      }
      if {[string first :: $objname] == -1} {
	set objname ${co}::$objname
      } else {
	error "Members to complex types must have explicitly declared labels."
      }
    }
    eval next $objname $args
  }
  
  ComplexType instproc init {{cmds ""}} {
    if {$cmds ne {}} {
      my slots $cmds
    }
    next
  }
  ::xotcl::Class Struct -superclass ComplexType

  ::xotcl::Class IArray
  IArray instproc asList {} {
    set r [list]
    foreach s [[my info class] info slots] {
      if {[my exists [$s name]]} {
	lappend r [my [$s name]]
      }
    }
    return $r
    # return slot objects in list, for looping etc.
  }
  ::xotcl::Class Array -superclass ComplexType -parameter {
    type
    size
  }
  Array instproc slots args {
    next;# ComplexType->slots
    # set size if not already done explicitly
  }
  Array instproc init {{cmds {}}} {
    if {[my exists type] && [my exists size] && $cmds eq {}} {
      my instvar type size
      for {set x 0} {$x<$size} {incr x} {
	append cmds "$type create $x\n" 
      }
      eval my slots [list $cmds]
      my superclass add IArray
    } else {
      eval my slots [list $cmds]
      my superclass add IArray
    }
  }
   
  
  ::xotcl::Class MetaType -superclass ::xotcl::Class
  MetaType instproc validate {value} {
    return [[[self] new -volatile] validate $value]
  }
  
  ::xotcl::Class SimpleType -superclass ::xotcl::Attribute
  SimpleType instproc init args {
    my type "my validate"
    next
  } 
  MetaType String -superclass SimpleType \
      -instproc validate {value} {
	return [string is print $value]
      }
  MetaType Boolean -superclass SimpleType \
      -instproc validate {value} {
	return [string is boolean $value]
      }
  MetaType Decimal -superclass SimpleType \
      -instproc validate {value} {
	return [regexp {^[+-]?(\d+(\.\d*)?|(\.\d+))$} $value]
	# return [regexp {^[+-]?\d+(\.\d*)?|(\.\d+)$} $value]
	# return [regexp {^[+-]?((\d+\.[0-9]+)|([0-9]+))$} $value]
	# return [regexp {^[+-]?((\d+\.\d*)|(\d+))$} $value]
      }
  
  MetaType Integer -superclass Decimal \
      -instproc validate {value} {
	set isDecimal [next];# Decimal->validate
	return [expr {$isDecimal && [string is integer $value]}]
      }
  
  MetaType Double -superclass Decimal \
      -instproc validate {value} {
	# see http://www.w3.org/TR/xmlschema-2/#double
	# 1) check for lexical / notational form: decimal / sic
	# 2) value space check for sic elements: mantissa / exponent
	# (\+|-)?((\d+(.\d*)?)|(.\d+))((e|E)(\+|-)?\d+)?|-?INF|NaN
	set isDecimal [next];# Decimal->validate
	if {[regexp -nocase {^-?inf|nan|0$} $value]} {
	  return 1
	} elseif {$isDecimal || \
		      [regexp {^[+-]?((\d+(.\d*)?)|(.\d+))(e|E)[+-]?\d+$} \
			   $value]} {
	  return [expr {pow(2,-1075) < abs($value) && abs($value) < pow(2,24)*pow(2,970)}]
	} else {
	  return 0
	}
      }
  MetaType Float -superclass Decimal \
      -instproc validate {value} {
	# see http://www.w3.org/TR/xmlschema-2/#float
	# 1) check for lexical / notational form: decimal / sic
	# 2) value space check for sic elements: mantissa / exponent
	set isDecimal [next];# Decimal->validate
	if {[regexp -nocase {^-?inf|nan|0$} $value]} {
	  return 1
	} elseif {$isDecimal || \
		      [regexp {^[+-]?((\d+(.\d*)?)|(.\d+))(e|E)[+-]?\d+$} \
			   $value]} {
	  return [expr {pow(2,-149) < abs($value) && abs($value) < pow(2,24)*pow(2,104)}]
	} else {
	  return 0
	}
      } 
  MetaType Date -superclass SimpleType  \
      -instproc validate {value} {
	return [regexp {^-?([1-9]\d\d\d+|0\d\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])(Z|(\+|-)(0\d|1[0-4]):[0-5]\d)?$} $value]
	#return [regexp {^\d{4}-\d{2}-\d{2}(Z|[+-].+|$)$} $value]
      }
  MetaType Time -superclass SimpleType  \
      -instproc validate {value} {
	return [regexp {^(([01]\d|2[0-3]):[0-5]\d:[0-5]\d(\.\d+)?|24:00:00(\.0+)?)(Z|(\+|-)(0\d|1[0-4]):[0-5]\d)?$} $value]
	#return [regexp {^\d{2}:\d{2}:\d{2}(Z|[+-].+|$)$} $value]
      }
  MetaType DateTime -superclass SimpleType \
      -instproc validate {value} {
	return [regexp {^-?([1-9]\d\d\d+|0\d\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])T(([01]\d|2[0-3]):[0-5]\d:[0-5]\d(\.\d+)?|24:00:00(\.0+)?)(Z|(\+|-)(0\d|1[0-4]):[0-5]\d)?$} $value]
	#return [regexp {^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-].+|$)$} \
	    # $value]
      }
  MetaType Base64Binary -superclass SimpleType \
      -instproc validate {value} {
	return [regexp {^((([A-Za-z0-9+/] ?){4})*(([A-Za-z0-9+/] ?){3}[A-Za-z0-9+/]|([A-Za-z0-9+/] ?){2}[AEIMQUYcgkosw048] ?=|[A-Za-z0-9+/] ?[AQgw] ?= ?=))?$} $value]
      }
  
  MetaType HexBinary -superclass SimpleType \
      -instproc validate {value} {
	return [string is xdigit $value]
      }


  namespace export Struct Array String Integer Double\
      Float Decimal DateTime Date Time Base64Binary HexBinary\
      Boolean
}
