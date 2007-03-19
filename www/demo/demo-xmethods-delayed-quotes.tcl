# # # # # # # # # # # # # # # # # # # # # # # # # #
# Demo: XMethods' Delayed Quote Service
# author: stefan.sobernig@wu-wien.ac.at
# # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # #
# staging
# # # # # # # # # # # # #

set title demo-xmethods-delayed-quote
set html "<html><title>$title</title><body>"
append html "<h2>$title</h2>"
# / / / / / / / / / / / /
# provide (remote / local) invocation handling 
::xotcl::Class instmixin :xorb::client::InvocationProxy

# / / / / / / / / / / / /
# declare the soap client stub
::xorb::client::Stub \
    StockQuoteStub -bind soap://services.xmethods.net:80/soap

# / / / / / / / / / / / /
# getQuote
StockQuoteStub ad_instproc \
    -uri "urn:xmethods-delayed-quotes" \
    getQuote \
    {-symbol:remote} \
    {Retrieve stock quote for company symbol} {}

# / / / / / / / / / / / /
# create a stub object
set stubInstance [StockQuoteStub new]

# / / / / / / / / / / / /
# issue remote invocation
set sym "IBM"

append html "<div>The stock quote for $sym is: [$stubInstance getQuote -symbol $sym]</div></body></html>"	
	
ns_return 200 text/html $html