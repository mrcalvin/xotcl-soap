ad_library {

  
  @author stefan.sobernig@wu-wien.ac.at
  @creation-date August, 23 2006
  @cvs-id $Id$

}

namespace eval xosoap::client {

  namespace import -force ::xosoap::*
  namespace import -force ::xorb::client::*

  
  ::xotcl::Class Soap::Stub -slots {
    Attribute uri
    Attribute schemas
    Attribute action
  }

  # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # # 
  # # Mixin Soap::Client
  # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # #
  ::xotcl::Class Soap::Client -superclass Soap::Stub
  Soap::Client instproc handleRequest {requestObj} {
    next; #ClientRequestHandler->handleRequest
  }
  Soap::Client instproc handleResponse {responseObj} {
    next; #ClientRequestHandler->handleResponse
  }
  
  # ============================
  ::xotcl::Class SoapPlugin -superclass ::xorb::client::RemotingProtocolPlugin -parameter {
    uri
    schemas
    action
  }
  SoapPlugin instproc requests args {

    my instvar operation uri schemas action bindingURI
    # proceed with remote invocation
    
    # (1) construe SOAP request object structure
    set requestEnvelope [::xosoap::marshaller::SoapEnvelope new]
    # (1a) populate SOAP request object 
    set requestVisitor [::xosoap::visitor::SoapRequestVisitor new -volatile -boundness "out"]
    $requestVisitor serviceMethod $operation
    $requestVisitor serviceArgs $args
    # processing protocol-specific settings
    if {[info exists uri] && $uri ne {}} {$requestVisitor targetNS $uri}
    set endpoint [string map {soap:// http://} $bindingURI]
    set actionHeader $endpoint
    if {[info exists action] && $action ne {}} {
      set actionHeader $action
    }
    $requestVisitor releaseOn $requestEnvelope
    # (2) employ / adapt SoapMarshallerVisitor
    set marshaller [::xosoap::visitor::SoapMarshallerVisitor new -volatile]
    $marshaller releaseOn $requestEnvelope
    # (3) delegate to transport layer (currently httpAccess, tclcurl will become optional)
    set payload [[$marshaller xmlDoc] asXML]
    my lastRequest $payload
    #set transportObj [::xosoap::client::SoapRequest new -volatile -endpoint $endpoint -payload $payload]
    set hr [HttpRequest new -url $endpoint \
		-headers [list SOAPAction $actionHeader] \
		-contentType "text/xml" \
		-data $payload \
		-method POST]
    set response [$hr response]
    my lastResponse $response
    my connectionTime [$hr connectTime]
    $hr destroy
    # (4) SoapDemarshallingVisitor
    # (5) parse Response Object structure
    set responseEnvelope [::xosoap::marshaller::SoapEnvelope new -response]
    set doc [dom parse $response]
    set root [$doc documentElement]
    $responseEnvelope parse $root
    # (6) return invocation results
    set responseVisitor [::xosoap::visitor::SoapResponseVisitor new -volatile -boundness "in"]
    $responseVisitor releaseOn $responseEnvelope
    return [$responseVisitor batch]
  }

  # +---------------------------+
  # | http/ https               |
  # | infrastructure            |
  # |                           |
  # |                           |
  # +---------------------------+
  #

  # # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # # #

  ::xotcl::Class HttpRequest -parameter {
    url 
    method 
    headers 
    data 
    contentType 
    connectTime
    response
  } 	-set userAgent "xosoap/0.2" \
      
  HttpRequest instproc destroy {} { my log "called, next=[self next]"; next}

  HttpRequest proc new args {
    set tclcurl_p [parameter::get -parameter use_tclcurl]
    if {$tclcurl_p && [my set tclcurl]} {
      return [eval CurlHttpRequest new $args]
    } else {
      set o [eval XoCommRequest new $args]
      my log "o=$o"
      return $o
    }
  }


  # # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # # #
  # httpAccess transport component
  # # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # # #

  if {![catch {package require xotcl::comm::httpAccess}]} {
    
    
    


    ::xotcl::comm::httpAccess::Http set useragent [HttpRequest set userAgent]
    
    ::Serializer exportObjects {
      ::xotcl::comm::httpAccess::Sink
      ::xotcl::comm::httpAccess::MemorySink
      ::xotcl::comm::httpAccess::TimeSink
      ::xotcl::comm::httpAccess::Access 
      ::xotcl::comm::httpAccess::NetAccess 
      ::xotcl::comm::httpAccess::Http
      ::xotcl::comm::httpAccess::SimpleRequest
      ::xotcl::comm::httpAccess::pwdManager
      ::xotcl::comm::mime::base64
      ::xotcl::comm::mime::Base64
      ::xotcl::comm::connection::Connection
    }
    
    ::xotcl::Class XoCommRequest -superclass {
      HttpRequest 
      ::xotcl::comm::httpAccess::SimpleRequest
    }
    XoCommRequest instproc init args {

      my timing 1
      my blocking 1
      set comment {if {[catch {next} msg]} {
	error "HTTP transport provided by xotcl::comm::httpAccess failed due to '$msg'"

      }}
      next
      my instvar sink
      $sink instvar startTime endTime
      my connectTime [expr {($endTime-$startTime)/1000000.0}]
      my response [my getContent]
    }
    XoCommRequest instproc destroy {} {
      my log "called, next=[self next]"
      next

    }

    # # # # # # # # # # # # # # # # # #
    # # # # # # # # # # # # # # # # # #
    # Workaround for thread-connection_object-socket asymmetry
    # # # # # # # # # # # # # # # # # #
    # # # # # # # # # # # # # # # # # #
    
    ::xotcl::Class ConnectionCleanup
    ConnectionCleanup instproc make args {
      if {[my exists openConnections]} {
	set availableSockets [file channels sock*]
	foreach {handle connObj} [my array get openConnections] {
	  set assignedSocket [$connObj socket]
	  if {[lsearch -exact $availableSockets $assignedSocket] == -1} {
	    my removeHandle $handle
	  }
	}
      }
      next
    }

    ::xotcl::comm::connection::Connection mixin ConnectionCleanup
    
  }

  # # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # # #
  # TclCurl transport component
  # # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # # #

  if {![catch {package require TclCurl}]} {

    ::xotcl::Class CurlConnection
    CurlConnection proc make {protocol host {port {}}} {
      my instvar openConnections
      if {$port ne {}} {
	set port :$port
      }
      set url [subst {$protocol://$host$port}]

      set handle $url
      #puts handle=$handle
      if {![info exists openConnections($handle)]} {
	set openConnections($handle) [CurlConnection new]
	return $openConnections($handle)
      } else {
	#puts "[self callingobject]: re-using connection for $handle"
      }

      return $openConnections($handle)
    }

    CurlConnection proc removeHandle {h} {
      my instvar openConnections
      if {[info exists openConnections($h)]} {
	my unset openConnections($handle)
      }
    }

    CurlConnection instproc init args {
      my instvar __handle__
      set __handle__ [curl::init]
      my forward configure $__handle__ %proc 
      my forward perform $__handle__ %proc
      my forward getinfo $__handle__ %proc
      next
    }

    CurlConnection instproc destroy {} {
      my instvar __handle__
      if {[info exists __handle__]} {
	$__handle__ cleanup
	set handle "[my protocol]://[my host][my port]"
	[self class] removeHandle $handle
      } 
      next
      
    }


    # # # # # # # # # # # # # # # # # #
    # # # # # # # # # # # # # # # # # #
    # curl/http

    ::xotcl::Class CurlHttpRequest -superclass HttpRequest
    CurlHttpRequest instproc init args {

      my instvar __connection__ url
      array set uriComposite [uri::split $url]
      
      set __connection__ [CurlConnection make $uriComposite(scheme) $uriComposite(host)/$uriComposite(path) $uriComposite(port)] 
      
      next
      my instvar method headers data contentType response
      
      $__connection__ configure -url $url
      $__connection__ configure -bodyvar response
      if {$method eq "POST"} {
	$__connection__ configure -post 1 -postfields $data
      }
      
      if {$contentType ne {}} {
	lappend headers Content-Type $contentType
      }
      

      if {$headers ne {}} {
	array set arrHeaders $headers
	set hList [list]
	foreach hElement [array names arrHeaders] {
	  lappend hList "$hElement: $arrHeaders($hElement)"
	}
	$__connection__ configure -httpheader $hList
      }
      
      $__connection__ configure -useragent [[[my info class] info superclass] set userAgent] 
      set startTime [clock clicks]
      set r [$__connection__ perform]

      set endTime [clock clicks]

      # time metric
      my connectTime [expr {($endTime-$startTime)/1000000.0}]
      #set ttime [expr {[$__connection__ getinfo totaltime] + [$__connection__ getinfo connecttime]}] 

      #my connectTime $ttime
      
      if {$r != 0} {
	set response $r
	$__connection__ destroy
      }

      
      
    }
    HttpRequest set tclcurl 1

  } else {
    HttpRequest set tclcurl 0
  }

}	


