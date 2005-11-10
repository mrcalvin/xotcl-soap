ad_page_contract {

        This page handles incoming SOAP requests and/or offers basic infos about        hosted services.

        @author Stefan Sobernig (stefan.sobernig@wu-wien.ac.at)
        @created 2005/08/12 
} -properties {
  title:onevalue
  output:onevalue
}

set title "xoSoap's Hideout"



#set ids [::xosoap::tsfInvoker do Invoker::ServiceRegistry getIds]

set output ""
foreach class [::xosoap::Service allinstances] {

    set service_methods ""
     set hoarded_methods ""
    if {[$class exists hoard]} {
    	set hoarded_methods [$class set hoard] } 
   
    foreach method [$class info instcommands] {

	set tmp ""
	ns_log notice "$method > $hoarded_methods"
	if {[string equal $hoarded_methods ""] || [expr { [lsearch  $hoarded_methods $method] eq "-1" }]} {
		
		append tmp $method
		append tmp "([$class info instargs $method])<br>"
	
		append service_methods $tmp	
	}



    }

    append output "<ul>"
    #append output "<li>Service: [::xosoap::Invoker::ServiceRegistry getField $id "service_name"]</li>"
    append output "<li>Service Class: $class</li>"
append output "<li>Service Methods: $service_methods</li>"
append output "</ul>"

}






