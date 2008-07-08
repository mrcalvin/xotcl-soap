::xosoap::Package initialize -ad_doc {

  A managing environment for running
  storm-based test suites. At some point,
  this will turn into a generic facility
  of ::xorb::Package or ::xorb::ProtocolPackage.

  @author stefan.sobernig@wu-wien.ac.at
  @creation-date November 13, 2007
  @cvs-id $Id$ 
}

set all {
  ::xosoap::tests::HttpEndpoint
  ::xosoap::tests::SOAPBuildersRound2BaseConsumer
  ::xosoap::tests::XosoapQuickStartEchoConsumer
}


::xotcl::Object TestRunner -set jobs $all -proc go {package} {
  my instvar jobs
  $package requireXorb
  $package instvar xorb
  foreach job $jobs {
    # / / / / / / / / / / / / / / / / 
    # Resolving suite file:
    # 1-) xosoap directory tree?
    # 2-) xorb directory tree?
    set filename [namespace tail $job]
    lappend paths "[get_server_root]/packages/[$package package_key]/www/admin/storm/${filename}.suite"
    lappend paths "[get_server_root]/packages/[$xorb package_key]/www/admin/storm/${filename}.suite"
    if {![my isobject $job]} {
      foreach path $paths {
	if {[file readable $path]} {
	  if {[catch {source $path} msg]} {
	    error "Sourcing '$path' failed: '$msg'."
	  } else {
	    break
	  }
	}
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