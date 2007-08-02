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

  ad_proc -private before-uninstall {} {
    # / / / / / / / / / / / / / / / /
    # Starting with 0.4, clearing
    # message types
    foreach sp [::xosoap::xsd::SoapPrimitive info instances ::xosoap::xsd::*] {
      $s delete
    }
    foreach sc [::xosoap::xsd::SoapComposite info instances ::xosoap::xsd::*] {
      $s delete
    }
  }
}