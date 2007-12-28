# / / / / / / / / / / / / / / / / / / / / / /
# Demo
# / / / / / / / / / / / / / / / / / / / / / /
# StockQuote example in simple
# ProxyObject notation. Remote end is
# http://www.webservicex.net/stockquote.asmx
# / / / / / / / / / / / / / / / / / / / / / /
# $Id$
# - - - - - - - - - - - - - - - - - - - - - - 
# NOTE: this demo consumer is meant to provide
# an insight on how-to use xosoap, the availability
# of the remote end is not guaranteed.
# - - - - - - - - - - - - - - - - - - - - - - 


namespace import -force ::xosoap::client::*
namespace import -force ::xorb::stub::*


# / / / / / / / / / / / / / / / / / / /
# 1) create a 'glue' object
set s1 [SoapGlueObject new \
	    -endpoint http://www.webservicex.net/stockquote.asmx \
	    -callNamespace "http://www.webserviceX.NET" \
	    -action "http://www.webserviceX.NET/GetQuote"]

# / / / / / / / / / / / / / / / / / / /
# 2) provide the 'object' to a proxy client /
# stub object and declare the remote object
# interface

ProxyObject StockQuote -glueobject $s1
StockQuote ad_proc -returns xsString GetQuote {
  -symbol:xsString
} {Retrieve quote for company symbol} {}

# / / / / / / / / / / / / / / / / / / /
# return the result
ns_return 200 text/plain "IBM's quote: [StockQuote GetQuote -symbol IBM]"
