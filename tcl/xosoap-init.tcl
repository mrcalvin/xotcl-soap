# / / / / / / / / / / / / / / /
# initialising and setting up
# all mounted instances of
# XoSoapPackage
namespace import -force ::xosoap::XoSoapPackage
set instances [apm_package_ids_from_key -package_key xotcl-soap -mounted]
foreach i $instances {
  XoSoapPackage initialise -package_id $i
}
