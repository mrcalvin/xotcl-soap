# / / / / / / / / / / / / / / / / / / /
# Demo: Simple SQI client
# / / / / / / / / / / / / / / / / / / /
# $Id$

namespace import ::xosoap::client::*

SoapObject SQISessionManager \
    -endpoint http://distance.ktu.lt/moodle/sqi/sessionmgt.php \
    -messageStyle ::xosoap::RpcEncoded

SQISessionManager ad_proc -returns xsString \
    createAnonymousSession {} {We, first, initiate a remote session} {
      set sessionId [next];# actual soap call
      ns_write "Session ID: $sessionId\n"
      return $sessionId
    }

SoapObject SQISource \
    -endpoint http://distance.ktu.lt/moodle/sqi/sqitarget.php \
    -messageStyle ::xosoap::RpcEncoded

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

set sid [SQISessionManager createAnonymousSession]
SQISource setQueryLanguage \
    -targetSessionID $sid \
    -queryLanguageID "keywords"
SQISource setResultsFormat \
    -targetSessionID $sid \
    -resultsFormat RSS_2.0
SQISource synchronousQuery \
    -targetSessionID $sid \
    -queryStatement "test" \
    -startResult 0
 