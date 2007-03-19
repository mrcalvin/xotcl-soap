ad_library {

  Setting the stage: register the Request Handler object 
  as filter for POST requests

  @author stefan.sobernig@wu-wien.ac.at
  @creation-date 2005-08-18
  @cvs-id $Id$
}

namespace import -force ::xosoap::*
	
set msg {
  ==xosoap== preauth filter set for $method 
  requests debarking at $filter_url.
}

set pkg_prefix "/xosoap"
set filter_url "$pkg_prefix*"
set method POST
ns_register_filter preauth $method $filter_url \
    SoapHttpListener; # SoapHttpListener->preauth
ns_log notice [subst $msg]														
ns_register_proc $method $pkg_prefix SoapHttpListener redirect		

# / / / / / / / / / / / / / / / / / / / / / / / / / / / 
# adding interceptors for GET requests 
# (requesting WSDL representations of Service Contracts)
set pkg_prefix "/xosoap/services"
set filter_url "$pkg_prefix*"
set method GET
ns_register_filter preauth $method "/xosoap/services*" \
    SoapHttpListener; # SoapHttpListener->preauth
ns_log notice [subst $msg]					
ns_register_proc $method $pkg_prefix SoapHttpListener redirect			
