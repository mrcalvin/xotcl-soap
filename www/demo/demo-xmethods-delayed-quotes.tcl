# / / / / / / / / / / / / / / / / / / /
# Demo
# / / / / / / / / / / / / / / / / / / /
# StockQuote example in simple
# ProxyObject notation 
# / / / / / / / / / / / / / / / / / / /
# $Id$


# # # # # # # # # # # # # # # # # # # # # # # # # #
# Demo: XMethods' Delayed Quote Service
# author: stefan.sobernig@wu-wien.ac.at
# # # # # # # # # # # # # # # # # # # # # # # # # #

namespace import -force ::xosoap::client::*
namespace import -force ::xorb::stub::*


# / / / / / / / / / / / / / / / / / / /
# 1) create a 'glue' object
set s1 [SoapGlueObject new \
	    -endpoint http://38.102.129.128:9090/soap \
	    -callNamespace "urn:xmethods-delayed-quotes" \
	    -action "urn:xmethods-delayed-quotes#getQuote"]

# / / / / / / / / / / / / / / / / / / /
# 2) provide the 'object' to a proxy client /
# stub object and declare the remote object
# interface

ProxyObject StockQuote -glueobject $s1
StockQuote ad_proc -returns xsString getQuote {
  -symbol:xsString
} {Retrieve quote for company symbol} {}

ns_write "IBM's quote: [StockQuote getQuote -symbol IBM]"
