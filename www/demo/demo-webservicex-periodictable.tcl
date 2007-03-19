# # # # # # # # # # # # #
# staging
# # # # # # # # # # # # #

set title demo-webservicex-periodictable
set html "<html><title>$title</title><body>"
append html "<h2>$title</h2>"
# / / / / / / / / / / / /
# provide (remote / local) invocation handling 
::xotcl::Class instmixin :xorb::client::InvocationProxy

# / / / / / / / / / / / /
# declare the soap client stub
::xorb::client::Stub \
    PeriodicTableStub -bind soap://www.webservicex.net/periodictable.asmx

# / / / / / / / / / / / /
# getAtoms
PeriodicTableStub ad_instproc \
    -uri "http://www.webserviceX.NET" \
    -action "http://www.webserviceX.NET/GetAtoms" \
    GetAtoms \
    {} \
    {Retrieve elements in periodic table} {}

# / / / / / / / / / / / /
# getAtoms
PeriodicTableStub ad_instproc \
    -uri "http://www.webserviceX.NET" \
    -action "http://www.webserviceX.NET/GetAtomicWeight" \
    GetAtomicWeight \
    {-ElementName:remote} \
    {Retrieve atomic weight for element specified} {}

# / / / / / / / / / / / /
# create a stub object
set stubInstance [PeriodicTableStub new]

# / / / / / / / / / / / /
# issue remote invocation
append html "<div>[$stubInstance GetAtomicWeight -ElementName Argon]</div></body></html>"	
	
ns_return 200 text/html $html