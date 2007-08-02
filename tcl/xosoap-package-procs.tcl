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
  ::xorb::PackageMgr Package -superclass ProtocolPackage
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

  namespace export Package
}