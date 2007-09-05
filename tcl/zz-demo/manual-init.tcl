# / / / / / / / / / / / / / / / /
# A little helper that sources
# the manual's soap provider
# examples upon init
set f [acs_package_root_dir xotcl-request-broker]/www/doc/manual/examples/xosoap/example-07-soap-provider-init.tcl
if {[file readable $f]} {
  uplevel #1 source $f
}
