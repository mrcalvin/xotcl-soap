# / / / / / / / / / / / / / / / / / / /
# Demo: Simple SQI client
# that exposes some compatibility
# issues with .NET Remoting
# / / / / / / / / / / / / / / / / / / /
# $Id$

namespace import ::xosoap::client::*

SoapObject SQISource \
    -endpoint http://course.isikun.edu.tr/colsqitarget/sqitarget.asmx \
    -messageStyle ::xosoap::RpcEncoded \
    -callNamespace [list m http://course.isikun.edu.tr/CoLSQI/SQITarget] \
    -action http://course.isikun.edu.tr/CoLSQI/SQITarget/%virtualCall


#/ / / / / / / / / / / / / / / / /
# -- to use a default namespace,
# use the following line instead:
# -callNamespace http://course.isikun.edu.tr/CoLSQI/SQITarget

SQISource ad_proc setQueryLanguage {
  -targetSessionID:xsString,glue
  -queryLanguageID:xsString,glue
} {Second, we configure the session with a ql id} {
  ns_write "Setting query language: $queryLanguageID\n"
  next;# actual soap call
}

SQISource ad_proc setResultsFormat {
  -targetSessionID:xsString,glue
  -resultsFormat:xsString,glue
} {Third, we configure the session with a result format} {
  ns_write "Setting result format: $resultsFormat\n"
  next;# actual soap call
}

SQISource ad_proc -returns xsString \
    synchronousQuery {
      -targetSessionID:xsString,glue
      -queryStatement:xsString,glue
      -startResult:xsInteger,glue
    } {Fourth, we issue the request} {
      ns_write "Querying for '$queryStatement' ...\n"
      set r [next];# actual soap call
      ns_write "... yields: [ad_quotehtml $r]\n"
    }

# / / / / / / / / / / / / / / / /
# SQI call sequence

set sid 1234
SQISource setQueryLanguage \
    -targetSessionID $sid \
    -queryLanguageID "KEY"
SQISource setResultsFormat \
    -targetSessionID $sid \
    -resultsFormat "RSS"
SQISource synchronousQuery \
    -targetSessionID $sid \
    -queryStatement "test" \
    -startResult 0
 