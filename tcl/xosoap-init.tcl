# / / / / / / / / / / / / / / /
# initialising and setting up
# all mounted instances of
# ::xosoap::Package
namespace import -force ::xosoap::Package
set instances [apm_package_ids_from_key -package_key xotcl-soap -mounted]
foreach i $instances {
  Package initialize -package_id $i
  ::$i onMount
}
