ad_library {

    Setting the stage: register the Request Handler object as filter for POST requests

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date 2005-08-18
    @cvs-id $Id$
}
											
set pkg_prefix "/xosoap"
set filter_url "$pkg_prefix*"

ns_register_filter preauth POST $filter_url	xosoap::ConcreteMessageHandler
ns_log notice "\[xoSoap\] preauth filter set for post requests debarking at $filter_url."														
ns_register_proc POST $pkg_prefix	xosoap::ConcreteMessageHandler preprocessRequest														

							
