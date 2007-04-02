ad_library {
  
  Library specifying xosoap-specific package-level callbacks
  
  @author stefan.sobernig@wu-wien.ac.at
  @creation-date April 2, 2007
  @cvs-id $Id$
}

namespace eval ::xosoap {

  ad_proc -private after-mount {
    -package_id
    -node_id
  } {} {
    set method POST
    # 1) get url path from node_id
    array set node [site_node::get -node_id $node_id]
    set url $node(url)
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
	SoapHttpListener; # SoapHttpListener->preauth
    ns_register_proc $method $suffix SoapHttpListener redirect
    ns_log notice [subst $msg]	
    # / / / / / / / / / / / / / / / / / / / / / / / / / / / 
    # adding interceptors for GET requests 
    # (requesting WSDL representations of Service Contracts)
    set method GET
    ns_register_filter preauth $method $filter_url \
	SoapHttpListener; # SoapHttpListener->preauth
    ns_register_proc $method $suffix SoapHttpListener redirect			
    ns_log notice [subst $msg]					
}

  ad_proc -private before-unmount {
    -package_id
    -node_id
  } {} {
    # 1) get url path from node_id
    array set node [site_node::get -node_id $node_id]
    set url $node(url)
    # 2) get virtual service node from package parameter (or default)
    set suffix [parameter::get -parameter service_url -package_id $package_id]
    # 3) unregister
    set suffix $url$suffix
    ns_unregister_proc POST $suffix
    ns_unregister_proc GET $suffix
    # / / / / / / / / / / / / / / / / 
    # TODO: how to unregister filter?
  }
}