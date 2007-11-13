::xosoap::Package initialize -ad_doc {

  A managing environment for running
  storm-based test suites. At some point,
  this will turn into a generic facility
  of ::xorb::Package or ::xorb::ProtocolPackage.

  @author stefan.sobernig@wu-wien.ac.at
  @creation-date November 13, 2007
  @cvs-id $Id$
  
}

::xotcl::Object TestRunner -set jobs {
  ::xosoap::tests::HttpEndpoint
} -proc go {package} {
  my instvar jobs
  foreach job $jobs {
    set filename [namespace tail $job]
    set path "[get_server_root]/packages/[$package package_key]/www/admin/storm/${filename}.suite"
    if {![my isobject $job] && [file readable $path]} {
      if {[catch {source $path} msg]} {
	error "Sourcing '$path' failed: '$msg'."
      }
    }
    $job volatile
    $job run
    ns_write [$job getReport]
  }
}

# - - - - - - - - - - - - -
TestRunner go ::$package_id
# - - - - - - - - - - - - -