# # # # # # # # # # # # # # # # # # # # # # # # # #
# Demo: XMethods' Foreign Exchange Demo Service
# see: http://www.xmethods.net/ve2/ViewListing.po;jsessionid=qrkN9OPNUNBHikcT2PMstrfo(QHyMHiRM)?key=uuid:D784C184-99B2-DA25-ED45-3665D11A12E5
# author: stefan.sobernig@wu-wien.ac.at
# # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # #
# staging
# # # # # # # # # # # # #

set title demo-xmethods-foreign-exchange
set html "<html><title>$title</title><body>"
append html "<h2>$title</h2>"
# / / / / / / / / / / / /
# provide (remote / local) invocation handling 
::xotcl::Class instmixin :xorb::client::InvocationProxy

# / / / / / / / / / / / /
# declare the soap client stub
::xorb::client::Stub \
    ForeignExchangeStub -bind soap://services.xmethods.net:80/soap

# / / / / / / / / / / / /
# getRate
ForeignExchangeStub ad_instproc \
    -uri "urn:xmethods-CurrencyExchange" \
    getRate \
    {-country1:remote -country2:remote} \
    {Retrieve exchange rate for two countries} {}

# / / / / / / / / / / / /
# create a stub object
set stubInstance [ForeignExchangeStub new]

# / / / / / / / / / / / /
# issue remote invocation
set c1 "uk"
set c2 "euro"

append html "<div>The exchange rate between '$c1' and '$c2' is: [$stubInstance getRate -country1 $c1 -country2 $c2]</div></body></html>"	
	
ns_return 200 text/html $html