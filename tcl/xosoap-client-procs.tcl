::xotcl::nonposArgs ad_proc remote {argName {string ""}} {} {}

package require xotcl::comm::httpAccess

::Serializer exportObjects {
 
 ::xotcl::comm::httpAccess::Sink
 ::xotcl::comm::httpAccess::MemorySink
 ::xotcl::comm::httpAccess::Access 
 ::xotcl::comm::httpAccess::NetAccess 
 ::xotcl::comm::httpAccess::Http
 ::xotcl::comm::httpAccess::SimpleRequest
 ::xotcl::comm::httpAccess::pwdManager
 ::xotcl::comm::mime::base64
 ::xotcl::comm::mime::Base64
 ::xotcl::comm::connection::Connection
  
}



namespace eval xosoap::client {

# +---------------------------+
# | ClientInvoker             |
# |                           |
# |                           |
# |                           |
# +---------------------------+
#
#	handles remote invocations, i.e.
#	message handling
#
#
#

::xotcl::Object Invoker

Invoker ad_proc invoke {-operation:required -endpoint:required {-uri ""} args} {} {

	# proceed with remote invocation
		
			# (1) construe SOAP request object structure
			set requestEnvelope [::xosoap::marshaller::SoapEnvelope new]
			# (1a) populate SOAP request object 
			set requestVisitor [::xosoap::visitor::SoapRequestVisitor new -volatile -boundness "out"]
			$requestVisitor serviceMethod $operation
			$requestVisitor serviceArgs $args
			if {$uri ne {}} {$requestVisitor targetNS $uri}
			$requestVisitor releaseOn $requestEnvelope
			# (2) employ / adapt SoapMarshallerVisitor
			set marshaller [::xosoap::visitor::SoapMarshallerVisitor new -volatile]
			$marshaller releaseOn $requestEnvelope
			my log "+++ outbound request: [[$marshaller xmlDoc] asXML]"
			# (3) delegate to transport layer (currently httpAccess, tclcurl will become optional)
			set payload [[$marshaller xmlDoc] asXML]
			set transportObj [::xosoap::client::SoapRequest new -volatile -endpoint $endpoint -payload $payload]
			
			# (4) SoapDemarshallingVisitor
			set response [$transportObj getContent]
			$transportObj destroy
			my log "+++ inbound response: $response"
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
# | Mixin class               |
# | RemoteInvocationProxy     |
# |                           |
# |                           |
# +---------------------------+
#
#	used to adapt xorb's InvocationProxy to support
#	invocation redirection to remote machines, using
#   SOAP (xosoap facilities); implements the adapter
#	pattern
#
#
#


::xotcl::Class SoapStubBuilder -superclass ::xorb::client::StubBuilder -parameter {uri schemas} -instproc init args  { 
	
	my set __callingobject [self callingobject]
	
	next
	
	
	set endpoint [string map {"soap://" "http://"} [my bind]]
	
	
	[self callingobject] instforward [my method] ::xosoap::client::Invoker invoke -operation %proc -endpoint $endpoint -uri [my uri] 
	
}

############
::xorb::client::InvocationProxy set builders(soap) ::xosoap::client::SoapStubBuilder
############

set comment {::xotcl::Class RemoteInvocationProxy -parameter {proxyFor realisedBy}

RemoteInvocationProxy instproc ad_instproc {
		
			-proxy:switch 
			{-for		""}
			{-realisedBy ""}
			{-uri ""}
			methodName 
			{arguments ""}
			{doc ""}
			{body ""}
		
	} {

	if {![info exists for] || $for eq {}} {set for [my set proxyFor]}
	set validReferrer [regexp -nocase {^(http|https)://[^ ].+} [string trim $for]]
	if {$proxy && $validReferrer} {
	# verifying remote proxy referrer (url, ...)

			
			my instforward $methodName ::xosoap::client::ClientInvoker invoke -operation %proc -endpoint $for -uri $uri --
			
			if { $body ne {} } {
			    set x [Class new]
			    $x ad_instproc $methodName $arguments $doc $body
			    my instmixin $x
			}
		
		} else {
			next -proxy -for $for -realisedBy $realisedBy $methodName $arguments $doc $body
		} 
	}
}



  namespace import -force  ::xotcl::comm::httpAccess::*

	# aligning to AOLServer environment

::xotcl::comm::httpAccess::Http set useragent "xosoap/1.0"

	
::xotcl::Class SoapRequest -superclass ::xotcl::comm::httpAccess::SimpleRequest -parameter {endpoint payload}
	
	SoapRequest ad_instproc init {} {} {
	
		my instvar endpoint payload
		
		my url $endpoint
		my method "POST"
		my headers [list SOAPAction $endpoint]
		my data $payload
		my contentType "text/xml"
		
		next
		
	}

}	



namespace eval xosoap {


    Class Client

    Client instproc ad_instproc {
	{-uri          ""}
	{-proxy        ""}
	{-params       ""}
	{-transport    ""}
	{-action       ""}
	{-wrapProc     ""}
	{-replyProc    ""}
	{-parseProc    ""}
	{-postProc     ""}
	{-command      ""}
	{-errorCommand ""}
	{-headers      ""}
	{-schemas      ""}
	{-version      ""}
	{-encoding     "http://schemas.xmlsoap.org/soap/encoding/"}
	procName 
	{arguments ""}
	{doc ""}
	{body ""}
    } {


	set params ""
	set posArgs [list]
	set nonposArgs [list]
	foreach arg $arguments {
	    if { [string index $arg 0] eq {-} } {
		lappend nonposArgs $arg
		if { [string last $arg :remote] } {
		    #nonposArg
		    lappend params [string trimleft [lindex [split $arg :] 0] -]
		    if { $arg eq {-startResult:remote} } {
			lappend params int
		    } else {
			lappend params string
		    }
		}
	    } else {
		lappend posArgs $arg
	    }
	}

	
	my requireNamespace

	set cmdName [self]::__$procName
	SOAP::create $cmdName \
	    -name $procName \
	    -uri $uri \
	    -proxy $proxy \
	    -params $params \
	    -transport $transport \
	    -action $action \
	    -wrapProc $wrapProc \
	    -replyProc $replyProc \
	    -parseProc $parseProc \
	    -postProc $postProc \
	    -command $command \
	    -errorCommand $errorCommand \
	    -httpheaders $headers \
	    -schemas $schemas \
	    -version $version \
	    -encoding $encoding 

	my instforward $procName $cmdName
	#my instproc $procName args "eval $cmdName \$args"

	if { $body ne {} } {
	    set x [Class new]
	    $x ad_instproc $procName $arguments $doc $body
	    my instmixin $x
	}

  }

}