# / / / / / / / / / / / / / / / / / / /
# Demo: simple echo client
# / / / / / / / / / / / / / / / / / / /
# 	- Object as Client Proxy
#	see http://www.whitemesa.com/interop.htm
# 	see http://websrv.cs.fsu.edu/~engelen/interop2.cgi
# / / / / / / / / / / / / / / / / / / /
# $Id$

namespace eval ::xosoap::demo::vienna {

  # / / / / / / / / / / / / / 
  # everything needed is found in
  # xosoap::client namespace
  namespace import -force ::xosoap::client::*

  # / / / / / / / / / / / / /
  # 1st step: define a 'glue'
  # object

  set glue [SoapGlueObject new \
		-endpoint http://websrv.cs.fsu.edu/~engelen/interop2.cgi \
		-callNamespace http://soapinterop.org/]

  # / / / / / / / / / / / / /
  # 2nd step: define the actual
  # client proxy

  ::xotcl::Object SimpleEcho -glueobject $glue
  SimpleEcho ad_glue -returns xsDateTime \
    proc echoDate {-inputDate:xsDateTime}\
    {see http://www.whitemesa.com/interop/proposal2.html#echoDate}
}

set echoDate [::xosoap::demo::vienna::SimpleEcho echoDate \
		  -inputDate 1956-10-18T22:20:00-07:00]

ns_write <pre>echoDate=$echoDate</pre>
