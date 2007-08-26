ad_library {

  xosoap comes with a package infrastructure, based
  upon recent xotcl-core package facilities.
  These facilities help to manage package scope
  more elegantly by encapsulated acs package contexts
  in object structures.

  @author stefan.sobernig@wu-wien.ac.at
  @cvs-id $Id$

}

namespace eval ::xosoap {
  namespace import -force ::xorb::ProtocolPackage
  namespace import -force ::xorb::PackageMgr
  namespace import -force ::xoexception::try
  
  ::xorb::PackageMgr Package -array set pageAttributes {
    title 	"xosoap"
    head 	""
    header_stuff ""
    context 	""
    content 	""
  } -superclass ProtocolPackage
  Package instproc onMount {} {
    my instvar node baseUrl
    set package_id [namespace tail [self]]
    # / / / / / / / / / / / / / / / /
    # the configuration step currently
    # involves injecting the necessary
    # interception rules into the
    # OpenACS request processor
    set method POST
    # 1) get url path from node_id
    array set nodeInfo [site_node::get -node_id $node]
    set url $nodeInfo(url)
    # 2) get virtual service node from package parameter (or default)
    #set suffix [parameter::get -parameter service_url]
    set suffix [parameter::get -parameter service_url -package_id $package_id]
    # 3) register for POST and GET interception
    set suffix $url$suffix
    set filter_url $suffix*
    set msg {
      ==xosoap== preauth filter/ proc set for $method 
      requests arriving at $filter_url.
    }
    ns_register_filter preauth $method $filter_url \
	::xosoap::SoapHttpListener; # SoapHttpListener->preauth
    ns_register_proc $method $suffix ::xosoap::SoapHttpListener redirect
    my log [subst $msg]	
    # / / / / / / / / / / / / / / / / / / / / / / / / / / / 
    # adding interceptors for GET requests 
    # (requesting WSDL representations of Service Contracts)
    set method GET
    ns_register_filter preauth $method $filter_url \
	::xosoap::SoapHttpListener; # SoapHttpListener->preauth
    ns_register_proc $method $suffix ::xosoap::SoapHttpListener redirect			
    my log [subst $msg]	
    next;# ProtocolPackage->onMount
  }
  Package instproc onUnmount {} {
    my instvar node baseUrl
    set package_id [namespace tail [self]]
    # 1) get url path from node_id
    array set nodeInfo [site_node::get -node_id $node]
    set url $nodeInfo(url)
    # 2) get virtual service node from package parameter (or default)
    set suffix [parameter::get -parameter service_url -package_id $package_id]
    # 3) unregister
    set suffix $url$suffix
    ns_unregister_proc POST $suffix
    ns_unregister_proc GET $suffix
    # / / / / / / / / / / / / / / / / 
    # TODO: how to unregister filter?
    next;# ProtocolPackage->remove
  }

  Package instproc acquireInvocationContext {} {
    my instvar listener protocol
    set ctxClass [$protocol contextClass]
    set context [$ctxClass new \
		     -destroy_on_cleanup]
    $context transport $listener
    $context protocol [my protocol]
    $context package [self]
    $context marshalledRequest [ns_conn content]
    if {[$listener exists fragment]} {
      $context virtualObject [$listener set fragment]
      $listener unset fragment
    }
    # / / / / / / / / / / / / / / / 
    # we require the SOAPAction header field to
    # be present in the http post request,
    # however its value is of no significance
    # (for endpoint resolution etc.)
    set headerSet [ns_conn header]
    set idx [ns_set find $headerSet SOAPAction]
    if {$idx ne "-1"} {
      # keep in context object for later use!
      # FIXED: apply trimming to header strings for
      # quotation marks!
      $context action [string trim [ns_set value $headerSet $idx] \"]
    }
    return $context
  }

  # / / / / / / / / / / / / / / / / / /
  # Simple page rendering
  # - - - - - - - - - - - - - - - - - - 
  
  Package instproc getExternalObjectId {internal} {
    set internal [string trim $internal "::"]
    set oidv [split [string map {:: /} $internal] /]
    set oidc [llength $oidv]
    my debug oidv=$oidv,oidc=$oidc
    switch -- $oidc {
      0 {
	error "Invalid internal object identifier."
      }
      1 {
	return [join [list acs $oidv ] /]
      }
      default {
	return [join $oidv /]
      }
    }
  }

  Package instproc getNewElement {elementTag} {
    return [[dom createDocument $elementTag] documentElement]
  }

  Package instproc popCss {filepath {media all}} {
    my instvar __css__
    set link [my getNewElement link]
    $link setAttribute rel stylesheet
    $link setAttribute type "text/css"
    $link setAttribute media $media
    $link setAttribute href $filepath
    lappend __css__ [$link asHTML]
  }

  Package instproc returnException {
    statusCode
    contentType 
    payload
  } {
    #my debug RETURN(statusCode)=$statusCode
    switch -- $statusCode {
      "500" {
	my instvar listener
	$listener dispatchResponse $statusCode $contentType $payload
      }
      default {
	my returnPage \
	    -adpTemplate /packages/xotcl-soap/www/xosoap-master \
	    -adpVariables [list content $payload title "xosoap exception"]
      }
    }
  }

  Package instproc returnPage {
    -adpTemplate:required
    {-adpVariables {[list]}}
  } {
    my instvar listener __css__ 
    [self class] instvar pageAttributes
    # / / / / / / / / / / / / / / / /
    # We pop header-related information
    # to the return template, assuming
    # that is uses the xosoap master.
    
    array set pageAttributes $adpVariables
    if {[info exists __css__] && [llength $__css__] > 0} {
      append pageAttributes(head) [join $__css__ \n]
    }
    set payload [template::adp_include \
		     $adpTemplate \
		     [array get pageAttributes]]
    #my debug PAYLOAD=$payload
    # / / / / / / / / / / / / / / / / /
    # clear state:
    if {[info exists __css__]} {
      my unset __css__
    }
    $listener dispatchResponse 200 text/html $payload
  }

  # / / / / / / / / / / / / / / / / / /
  # Relevant methods for invocation/ 
  # wui handling
  # - - - - - - - - - - - - - - - - - -     
  Package instproc solicit=invocation {} {
    # / / / / / / / / / / / / / / / 
    # create the invocation context
    my instvar protocol listener
    set context [my acquireInvocationContext]
    # / / / / / / / / / / / / / / / 
    # dispatch guards to enforce
    # - if post, action header present
    # - if post, object identifier present in uri
    # - if post, payload present
    # - - - - - - - - - - - - - - - 
    # - if get, object present query param present (?)
    if {[::xo::cc isPost]} {
      if {![$context exists action]} {
	error [MalformedEndpointException new [subst {
	  No header field 'SOAPAction' present in 
	  HTTP post request.
	}]]
      }
      if {![$context exists virtualObject]} {
	error [MalformedEndpointException new [subst {
	  No object identifier information given 
	  in resource locator '[::xo::cc url]'.
	}]]
      }
      if {[$context marshalledRequest] eq {}} {
	error [HttpRequestException new {
	  Payload is missing in POST request
	}]
      }
    } else {
      #- is a GET request
      # TODO: currently, we do not allow for
      # GET-based invocations, this will
      # certainly change in a not so far
      # future.
      # In that case, check for:
      # - isGet on ::xo::cc
      # - and ask for a specific query
      # parameter that carries the
      # object id.
      error [HttpRequestException new {
	Invocation calls through HTTP GET are currently
	not supported.
      }]
    }
    next $context;#ProtocolPackage->solicit=invocation
  }

  Package instproc wsdlDocument {context} {
   # set context [my acquireInvocationContext]
    if {[::xo::cc isGet] && [$context exists virtualObject]} {
      ::xorb::Invoker mixin add ::xosoap::Soap::Invoker
      set objectId [::xorb::Invoker resolve [$context virtualObject]]
      ::xorb::Invoker mixin delete ::xosoap::Soap::Invoker
      ::xorb::Skeleton mixin add ::xosoap::Wsdl1.1
      set implObj [::xorb::Skeleton getImplementation \
		       -name $objectId]
      return [::xorb::Skeleton getContract \
		  -name [$implObj implements]]
      ::xorb::Skeleton mixin delete ::xosoap::Wsdl1.1
    } else {
      error [UIRequestException new [subst {
	Requesting a WSDL document through \
	    '[::xo::cc url]' ([::xo::cc httpMethod]) failed.
      }]]
    }
  }

  Package instproc solicit=wsdl {} {
    my instvar listener
    set context [my acquireInvocationContext]
    $listener dispatchResponse 200 text/xml [[my wsdlDocument $context] asXML]
  }
  
  Package instproc solicit=badge {} {
    my instvar listener
    # single service badge
    ::xoexception::try {
      set context [my acquireInvocationContext]
      my debug CONTEXT=[$context serialize]
      if {[$context exists virtualObject]} {
	# single service badge
	set xsltFile [open [my getPackagePath]/www/badge.xsl r]
	set xslt [read $xsltFile]
	close $xsltFile
	my debug xslt=$xslt
	set xsltDoc [dom parse $xslt]
	set wsdlDoc [dom parse [[my wsdlDocument $context] asXML]]
	set badgeDoc [$wsdlDoc xslt $xsltDoc]
	set adpVariables [list \
			      content [$badgeDoc asHTML] \
			      title "xosoap service badge"]
	my debug content=[$badgeDoc asHTML]
      } else {
	# all-services
	# currently, restricted to
	# xorb-based service
	# implementations
	#set inItems [::xorb::ServiceImplementation query allSubTypes]
	set type ::xorb::AcsScImplementation
	lappend innerSelect [subst {
	  (select 1 from acs_objects 
	   where acs_objects.object_type in ('::xorb::ServiceImplementation') 
	   and acs_objects.object_id = [$type table_name].[$type id_column]) 
	  as is_xorb_object, acs_objects.object_id}]
	lappend froms {acs_sc_bindings binds}
	lappend wheres {binds.impl_id = acs_objects.object_id}
	set items {}
	set counter 0
	db_foreach [my qn all_service_badge] \
	    [$type query \
		 -subtypes \
		 -selectClauses $innerSelect \
		 -whereClauses $wheres \
		 -from $froms "allInstances"] {
		   if {$is_xorb_object == 1} {
		     append items [subst {
		       ::html::li {
			 ::html::a -href \
			     "[my getExternalObjectId $impl_name]?s=badge" {
			       ::html::t $impl_name
			     }
			 ::html::t " | "
			 ::html::a -href \
			     "[my getExternalObjectId $impl_name]?s=wsdl" {
			       ::html::t wsdl
			     }
		       }
		     }]
		     incr counter
		   }
		 }
	::require_html_procs
	if {$counter > 0} {set counter "$counter services deployed"}
	dom createDocument div doc1
	set r [$doc1 documentElement]
	$r setAttribute class head
	$r appendFromScript [subst {
	  ::html::span -class xo {
	    ::html::t xo
	  }
	  ::html::t "[join [list soap $counter] { | }]"
	}]
	dom createDocument ul doc
	set root [$doc documentElement]
	$root appendFromScript $items
	$root setAttribute class badge
	
	set adpVariables [list \
			      content "[$r asHTML][$root asHTML]" \
			      title "xosoap: service overview"]
      }
      my popCss /resources/xotcl-soap/xosoap.css
      my returnPage \
	  -adpTemplate /packages/xotcl-soap/www/xosoap-master \
	  -adpVariables $adpVariables
    } catch {Exception e} {
      error [UIRequestException new $e]
    } catch {error e} {
      error [UnknownUIRequestException new $e]
    }
  }

  namespace export Package
}