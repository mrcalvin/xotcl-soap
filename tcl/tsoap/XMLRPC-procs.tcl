# XMLRPC.tcl - Copyright (C) 2001 Pat Thoyts <patthoyts@users.sourceforge.net>
#
# Provide Tcl access to XML-RPC provided methods.
#
# See http://tclsoap.sourceforge.net/ for usage details.
#
# -------------------------------------------------------------------------
# This software is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the accompanying file `LICENSE'
# for more details.
# -------------------------------------------------------------------------

# package require SOAP 1.4
# package require rpcvar

namespace eval ::XMLRPC {
    variable version 1.0
    variable rcs_version { $Id: XMLRPC-procs.tcl,v 1.1 2005/03/17 17:59:32 maltes Exp $ }

    namespace export create cget dump configure proxyconfig export
    catch {namespace import -force [uplevel {namespace current}]::rpcvar::*}
}

# -------------------------------------------------------------------------

# Delegate all these methods to the SOAP package. The only difference between
# a SOAP and XML-RPC call are the method call wrapper and unwrapper.

proc ::XMLRPC::create {args} {
    set args [linsert $args 1 \
            -wrapProc [namespace origin \
                [namespace parent]::SOAP::xmlrpc_request] \
            -parseProc [namespace origin \
                [namespace parent]::SOAP::parse_xmlrpc_response]]
    return [uplevel 1 "SOAP::create $args"]
}

proc ::XMLRPC::configure { args } {
    return [uplevel 1 "SOAP::configure $args"]
}

proc ::XMLRPC::cget { args } {
    return [uplevel 1 "SOAP::cget $args"] 
}

proc ::XMLRPC::dump { args } {
    return [uplevel 1 "SOAP::dump $args"] 
}

proc ::XMLRPC::proxyconfig { args } {
    return [uplevel 1 "SOAP::proxyconfig $args"] 
}

proc ::XMLRPC::export {args} {
    foreach item $args {
        uplevel "set \[namespace current\]::__xmlrpc_exports($item)\
                \[namespace code $item\]"
    }
    return
}

# -------------------------------------------------------------------------

# Description:
#   Prepare an XML-RPC fault response
# Parameters:
#   faultcode   the XML-RPC fault code (numeric)
#   faultstring summary of the fault
#   detail      list of {detailName detailInfo}
# Result:
#   Returns the XML text of the SOAP Fault packet.
#
proc ::XMLRPC::fault {faultcode faultstring {detail {}}} {
    set xml [join [list \
	    "<?xml version=\"1.0\" ?>" \
	    "<methodResponse>" \
	    "  <fault>" \
	    "    <value>" \
	    "      <struct>" \
	    "        <member>" \
	    "           <name>faultCode</name>"\
	    "           <value><int>${faultcode}</int></value>" \
	    "        </member>" \
	    "        <member>" \
	    "           <name>faultString</name>"\
	    "           <value><string>${faultstring}</string></value>" \
	    "        </member>" \
	    "      </struct> "\
	    "    </value>" \
	    "  </fault>" \
	    "</methodResponse>"] "\n"]
    return $xml
}

# -------------------------------------------------------------------------

# Description:
#   Generate a reply packet for a simple reply containing one result element
# Parameters:
#   doc         empty DOM document element
#   uri         URI of the SOAP method
#   methodName  the SOAP method name
#   result      the reply data
# Result:
#   Returns the DOM document root of the generated reply packet
#
proc ::XMLRPC::_reply {doc uri methodName result} {
    set doc [dom createDocument "methodResponse"]
    set d_root [$doc documentElement]
    set d_params [$doc createElement "params"]
    $d_root appendChild $d_params
    set d_param [$doc createElement "param"]
    $d_params appendChild $d_param
    insert_value $d_param $result
    return $doc
}

# -------------------------------------------------------------------------
# Description:
#   Generate a reply packet for a reply containing multiple result elements
# Parameters:
#   doc         empty DOM document element
#   uri         URI of the SOAP method
#   methodName  the SOAP method name
#   args        the reply data, one element per result.
# Result:
#   Returns the DOM document root of the generated reply packet
#
proc ::XMLRPC::reply {doc uri methodName args} {
    set d_root [dom createDocument "methodResponse"]
    set d_root [$doc documentElement]
    set d_params [$doc createElement "params"]
    $d_root appendChild $d_params

    foreach result $args {
        set d_param [$doc createElement "param"]
        $d_params appendChild $d_param
        insert_value $d_param $result
    }
    return $doc
}

# -------------------------------------------------------------------------

# node is the <param> element
proc ::XMLRPC::insert_value {node value} {

    set type      [rpctype $value]
    set value     [rpcvalue $value]
    set typeinfo  [typedef -info $type]
    set doc [SOAP::Utils::getDocumentElement $node]

    set value_elt [$doc createElement "value"]
    $node appendChild $value_elt

    if {[string match {*()} $type] || [string match array $type]} {
        # array type: arrays are indicated by a () suffix of the word 'array'
        set itemtype [string trimright $type ()]
        if {$itemtype == "array"} {
            set itemtype "any"
        }
        set array_elt [$doc createElement "array"]
        $value_elt appendChild $array_elt
        set data_elt [$doc createElement "data"]
        $array_elt appendChild $data_elt
        foreach elt $value {
            if {[string match $itemtype "any"] || \
                [string match $itemtype "ur-type"] || \
                [string match $itemtype "anyType"]} {
                XMLRPC::insert_value $data_elt $elt
            } else {
                XMLRPC::insert_value $data_elt [rpcvar $itemtype $elt]
            }
        }
    } elseif {[llength $typeinfo] > 1} {
        # a typedef'd struct
        set struct_elt [$doc createElement "struct"]
        $value_elt appendChild $struct_elt
        array set ti $typeinfo
        foreach {eltname eltvalue} $value {
            set member_elt [$doc createElement "member"]
            $struct_elt appendChild $member_elt
            set name_elt [$doc createElement "name"]
            $member_elt appendChild $name_elt
            $name_elt appendChild [$doc createTextNode $eltname]
            if {![info exists ti($eltname)]} {
                error "invalid member name: \"$eltname\" is not a member of\
                        the $type type."
            }
            XMLRPC::insert_value $member_elt [rpcvar $ti($eltname) $eltvalue]
        }

    } elseif {[string match struct $type]} {
        # an undefined struct
        set struct_elt [$doc createElement "struct"]
        $value_elt appendChild $struct_elt
        foreach {eltname eltvalue} $value {
            set member_elt [$doc createElement "member"]
            $struct_elt appendChild $member_elt
            set name_elt [$doc createElement "name"]
            $member_elt appendChild $name_elt
            $name_elt appendChild [$doc createTextNode $eltname]
            XMLRPC::insert_value $member_elt $eltvalue
        }
    } else {
        # simple type.
        set type_elt [$doc createElement $type]
        $value_elt appendChild $type_elt
        $type_elt appendChild [$doc createTextNode $value]
    }    
}

# -------------------------------------------------------------------------

package provide XMLRPC $XMLRPC::version

# -------------------------------------------------------------------------

# Local variables:
#    indent-tabs-mode: nil
# End:
