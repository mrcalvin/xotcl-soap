# / / / / / / / / / / / / / / / / / / /
# Demo
# / / / / / / / / / / / / / / / / / / /
# StockQuote example in simple
# GObject notation 
# / / / / / / / / / / / / / / / / / / /
# $Id$

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

GObject StockQuote -glueobject $s1
StockQuote ad_proc -returntype string GetQuote {
  -symbol
} {Retrieve quote for company symbol} {}

# / / / / / / / / / / / / / / / / / / /
# return the result
ns_return 200 text/plain "IBM's quote: [StockQuote GetQuote -symbol IBM]"