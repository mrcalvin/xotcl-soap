# xpath.tcl - Copyright (C) 2001 Pat Thoyts <patthoyts@users.sourceforge.net>
#
# Provide a _SIGNIFICANTLY_ simplified version of XPath querying for DOM
# document objects. This might get expanded to eventually conform to the
# W3Cs XPath specification but at present this is purely for use in querying
# DOM documents for specific elements by the SOAP package.
#
# Subject to interface changes
#
# -------------------------------------------------------------------------
# This software is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the accompanying file `LICENSE'
# for more details.
# -------------------------------------------------------------------------

package require tdom

namespace eval SOAP::xpath {
    variable version 0.2
    variable rcsid { $Id: xpath-procs.tcl,v 1.1 2005/03/17 17:59:32 maltes Exp $ }
    namespace export xpath xmlnsSplit
}

# -------------------------------------------------------------------------

# Given Envelope/Body/Fault and a DOM node, see if we can find a matching
# element else return {}

# TODO: Paths including attribute selection etc.

proc ::SOAP::xpath::xpath { args } {
    if { [llength $args] < 2 || [llength $args] > 3 } {
        return -code error "wrong # args:\
            should be \"xpath ?option? rootNode path\""
    }

    array set opts {
        -node        0
        -name        0
        -attributes  0
    }

    if { [llength $args] == 3 } {
        set opt [lindex $args 0]
        switch -glob -- $opt {
            -nod*   { set opts(-node) 1 }
            -nam*   { set opts(-name) 1 }
            -att*   { set opts(-attributes) 1 }
            default {
                return -code error "bad option \"$opt\":\
                    must be [array names opts]"
            }
        }
        set args [lrange $args 1 end]
    }

    set root [lindex $args 0]
    set path [lindex $args 1]

    # split the path up and call find_node to get the new node or nodes.
    set root [find_node $root [split [string trimleft $path {/}] {/}]]

    # return the elements value (if any)
    if { $opts(-node) } {
        return $root
    }

    set value {}
    if { $opts(-attributes) } {
        foreach node $root {
            append value [array get [$node attributes]]
        }
        return $value
    }

    if { $opts(-name) } {
        foreach node $root {
            lappend value [$node nodeName]
        }
        return $value
    }

    foreach node $root {
        set children [$node child all]
        set v ""
        foreach child $children {
            append v [string trim [$child nodeValue] "\n"]
        }
        lappend value $v
    }
    return $value
}

# -------------------------------------------------------------------------

# check for an element (called $target) that is a child of root. Returns
# the node(s) or {}
proc ::SOAP::xpath::find_node { root pathlist } {
    set r {}
    set kids ""

    if { $pathlist == {} } {
        return {} 
    }

    #set target [split $path {/}]
    set remainder [lrange $pathlist 1 end]
    set target [lindex $pathlist 0]

    # split the target into XML namespace and element names.
    set targetName [xmlnsSplit $target]
    set targetNamespace [lindex $targetName 0]
    set targetName [lindex $targetName 1]

    # get information about the child elements.
    foreach element $root { 
        append kids [child_elements $element]
    }

    # match name and (optionally) namespace
    foreach {node ns elt} $kids {
        if { [string match $targetName $elt] } {
            #puts "$node nodens=$ns elt=$elt targetNS=$targetNamespace\
                    #targetName=$targetName"
            if { $targetNamespace == {} || [string match $targetNamespace $ns] } {
                if {$remainder != ""} {
                    set rr [find_node $node $remainder]
                } else {
                    set rr $node
                }
                set r [concat $r $rr]
                #puts "$kids : $targetName : $remainder -> $r"
            }
        }
    }

    # Flatten the list out.
    return [eval "list $r"]
}

# -------------------------------------------------------------------------

# Return list of {node namespace elementname} for each child element of root
proc ::SOAP::xpath::child_elements { root } {
    set kids {}
    set children [$root child all]
    foreach node $children {
        set type [string trim [$node nodeType ]]
        if { $type == "element" } {
            catch {unset xmlns}
            array set xmlns [xmlnsConstruct $node]

            #set name [xmlnsQualify xmlns [$node nodeName]]
            set name [$node nodeName]
            set name [xmlnsSplit $name]
            lappend kids $node [lindex $name 0] [lindex $name 1]
        }
    }
    return $kids
}

# -------------------------------------------------------------------------

# Description:
#   Split a DOM element tag into the namespace and tag components. This
#   will even work for fully qualified namespace names eg:
#      Body                      -> {} Body
#      SOAP-ENV:Body             -> SOAP-ENV Body
#      urn:test:Body             -> urn:test Body
#      http://localhost:80/:Body -> http://localhost:80/ Body
#
proc ::SOAP::xpath::xmlnsSplit {elementName} {
    set name [split $elementName :]
    set len [llength $name]
    if { $len == 1 } {
        set ns {}
    } else {
        incr len -2
        set ns   [join [lrange $name 0 $len] :]
        set name [lindex $name end]
    }
    return [list $ns $name]
}

# -------------------------------------------------------------------------

# Build a list of any XML namespace definitions for node
# Returns a list of {namesnameName qualifiedName}
#
proc ::SOAP::xpath::xmlnsGet {node} {
    set result {}
    foreach {ns fqns} [array get [$node attributes]] {
	set ns [split $ns :]
	if { [lindex $ns 0] == "xmlns" } {
	    lappend result [lindex $ns 1] $fqns
	}
    }
    return $result
}

# -------------------------------------------------------------------------

# Build a list of {{xml namespace name} {qualified namespace}} working up the
# DOM tree from node. You should look for the last occurrence of your name
# in the list.
proc ::SOAP::xpath::xmlnsConstruct {node} {
    set result [xmlnsGet $node]
    set parent [$node parentNode]
    while { [$parent nodeType] == "element" } {
        set result [concat [xmlnsGet $parent] $result]
        set parent [$parent parentNode]
    }
    return $result
}

# -------------------------------------------------------------------------

# Split an XML element name into its namespace and name parts and return
# a fully qualified XML element name.
# xmlnsNamespaces should be an array of namespaceNames to qualified names
# constructed using array set var [xmlnsConstruct $node]
#
proc ::SOAP::xpath::xmlnsQualify {xmlnsNamespaces elementName} {
    upvar $xmlnsNamespaces xmlns
    set name [split $elementName :]
    if { [llength $name] == 1} {
        return $elementName
    }
    if { [llength $name] != 2 } {
	return -code error "wrong # elements:\
            name should be namespaceName:elementName"
    }
    if { [catch {set fqns $xmlns([lindex $name 0])}] } {
	return -code error "invalid namespace name:\
            \"[lindex $name 0]\" not found"
    }

    return "${fqns}:[lindex $name 1]"
}

# -------------------------------------------------------------------------

package provide SOAP::xpath $::SOAP::xpath::version

# -------------------------------------------------------------------------
# Local variables:
#   indent-tabs-mode: nil
# End:
