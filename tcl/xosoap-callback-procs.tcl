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
    ::xosoap::XoSoapPackage initialise \
	-package_id $package_id \
	-node_id $node_id
  }

  ad_proc -private before-unmount {
    -package_id
    -node_id
  } {} {
    if {[::xotcl::Object isobject ::$package_id]} {
      ::$package_id remove
    }
  }
}