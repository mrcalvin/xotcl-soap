# / / / / / / / / / / / / / / / / / / / / / /
# Demo consumer for Periodic Table service
# at http://www.webservicex.net/periodictable.asmx
# - - - - - - - - - - - - - - - - - - - - - - 
# NOTE: this demo consumer is meant to provide
# an insight on how-to use xosoap, the availability
# of the remote end is not guaranteed.
# - - - - - - - - - - - - - - - - - - - - - - 

namespace import ::xosoap::client::*

set title demo-webservicex-periodictable
set html "<html><title>$title</title><body>"
append html "<h2>$title</h2>"

# Declare a combined proxy and glue object
# / / / / / / / / / / / / / / / / / / / / /
# 
SoapObject PeriodicTableProxy \
    -endpoint http://www.webservicex.net/periodictable.asmx \
    -callNamespace http://www.webserviceX.NET \
    -action http://www.webserviceX.NET/%virtualCall


# Operation: GetAtoms
# / / / / / / / / / / / / / / / / / / / / /
# 
PeriodicTableProxy ad_proc -returns xsString \
    GetAtoms {} {Retrieve elements in periodic table} {}


# Operation: GetAtomicWeight
# / / / / / / / / / / / / / / / / / / / / /
# 
PeriodicTableProxy ad_proc -returns xsString \
    GetAtomicWeight {-ElementName:xsString} \
    {Retrieve atomic weight for element specified} {}

# Issue sample invocation
# / / / / / / / / / / / / / / / / / / / / /
# 
append html "<div>[PeriodicTableProxy GetAtomicWeight -ElementName Argon]</div></body></html>"	
	
ns_return 200 text/html $html