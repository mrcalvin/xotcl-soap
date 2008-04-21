::xo::library doc {
  
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
    ::xosoap::Package initialize \
	-package_id $package_id
    ::$package_id node $node_id
    ::$package_id onMount
  }

  ad_proc -private before-unmount {
    -package_id
    -node_id
  } {} {
    if {[::xotcl::Object isobject ::$package_id]} {
      ::$package_id onUnmount
    }
  }
}