# / / / / / / / / / / / / / / / / / / /
# Demo, a simple SQI Source Client
# / / / / / / / / / / / / / / / / / / /
# SQI Client
# - example in simple GObject notation 
# - per-method glue object 
# - see http://julia.wu-wien.ac.at:8080/axis2/services/Target 
# / / / / / / / / / / / / / / / / / / /
# $Id$


namespace import -force ::xosoap::client::*
namespace import -force ::xorb::stub::*


# / / / / / / / / / / / / / / / / / / /
# 1) create a 'glue' object
set s1 [SoapGlueObject new \
	    -endpoint http://julia.wu-wien.ac.at:8080/axis2/services/SessionManagement \
	    -callNamespace urn:www.cenorm.be/isss/ltws/wsdl/SQIv1p0/createAnonymousSession]
set  s2  [SoapGlueObject new \
	    -endpoint http://julia.wu-wien.ac.at:8080/axis2/services/Target
]

GObject SessionManagementClient -glueobject $s1
SessionManagementClient ad_proc \
    -returns xsString\
    createAnonymousSession \
    {} \
    {initiates anonym session} {}
    

GObject SQIClient -glueobject $s2
SQIClient ad_proc \
    setQueryLanguage \
    {-targetSessionID:xsString -queryLanguageID:xsString} \
    {doc} {}
  
SQIClient ad_proc \
    setResultsFormat \
    {-targetSessionID:xsString -resultsFormat:xsString} \
    {doc} {}  


SQIClient ad_proc \
    -returns xsString \
    synchronousQuery \
    {-targetSessionID:xsString -queryStatement:xsString -startResult:xsString} \
    {doc} {} 

set id [SessionManagementClient createAnonymousSession]
ns_write id=$id
SQIClient setResultsFormat -targetSessionID $id -resultsFormat RSS20Results
SQIClient setQueryLanguage -targetSessionID $id -queryLanguageID KeywordQuery

set result [SQIClient synchronousQuery -targetSessionID $id -queryStatement test -startResult 1]
ns_log notice result=$result
#ns_write result=[ad_quotehtml $result]
    