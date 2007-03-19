# # # # # # # # # # # # #
# staging
# # # # # # # # # # # # #

set title demo-webservicex-stockquote
set html "<html><title>$title</title><body>"
append html "<h2>$title</h2>"
# / / / / / / / / / / / /
# provide (remote / local) invocation handling 
::xotcl::Class instmixin :xorb::client::InvocationProxy

# / / / / / / / / / / / /
# declare the soap client stub
::xorb::client::Stub \
    StockQuoteStub -bind soap://www.webservicex.net/stockquote.asmx

# / / / / / / / / / / / /
# getQuote
StockQuoteStub ad_instproc \
    -uri "http://www.webserviceX.NET" \
    -action "http://www.webserviceX.NET/GetQuote" \
    GetQuote \
    {-symbol:remote} \
    {Retrieve quote for company symbol} {}

# / / / / / / / / / / / /
# create a stub object
set stubInstance [StockQuoteStub new]

# / / / / / / / / / / / /
# issue remote invocation
append html "<div>[$stubInstance GetQuote -symbol IBM]</div></body></html>"	
	
ns_return 200 text/html $html