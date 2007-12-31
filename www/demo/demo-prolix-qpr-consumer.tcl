# Demo consumer
# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /
# A simple rpc/encoded consumer realised
# for a PROLIX (http://prolix-project.org)
# sub-project. 
# The interface description is to be found
# at http://marla.wu-wien.ac.at/Scripts/QPR_PROLIX.dll/wsdl/IPROLIX_QPR_Interface
# The availability of the remote end is not guaranteed.
# contact: amulley@wu-wien.ac.at
# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /
# $Id $

namespace import ::xosoap::client::*
namespace import ::xorb::stub::*

set glueObject [SoapGlueObject new \
		    -endpoint "http://marla.wu-wien.ac.at/Scripts/qpr_prolix.dll/soap/IPROLIX_QPR_Interface" \
		    -action "urn:PROLIX_QPR_InterfaceIntf-IPROLIX_QPR_Interface#%virtualCall" \
                    -messageStyle ::xosoap::RpcEncoded]

ProxyObject AddDataSeriesConsumer -glueobject $glueObject

AddDataSeriesConsumer ad_proc -returns xsString\
    addDataSeries {
      -MODEL_NAME:xsString
      -SC_ID:xsString
      -MEA_NAME:xsString
      -MEA_ID:xsString
      -MEA_VALUE:xsDouble
      -MEA_DATE:xsDateTime
      -MEA_SERIES:xsString
    } {
      The Call will send the defined parameters to the QPR webservice
    } {}


set metric_id "some-id"

ns_write "AddDataSeriesConsumer: Sending an addDataSeries request"

set result [AddDataSeriesConsumer addDataSeries \
    -MODEL_NAME "Prolix Procar" \
    -SC_ID "ALPHALOG" \
    -MEA_NAME "Satisfaction with Learning Management" \
    -MEA_ID $metric_id \
    -MEA_VALUE 0 \
    -MEA_DATE "2007-12-13T10:39:10.234Z" \
    -MEA_SERIES "ACT"]

ns_write "AddDataSeriesConsumer: Retrieved result $result"


