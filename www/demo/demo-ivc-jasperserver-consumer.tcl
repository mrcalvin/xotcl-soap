# Demo consumer
# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /
# The demo is meant as show case following-up on the discussion
# at http://openacs.org/forums/message-view?message%5fid=1392533
#
# The availability of the remote end or mock service is not guaranteed.
# contact: Justis Peters <justis@ivc.com>
# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /
# $Id $

namespace import ::xosoap::client::*

SoapObject JasperServerConsumer \
    -endpoint http://localhost:8080/ \
    -action "" \
    -callNamespace {m http://axis2.ws.jasperserver.jaspersoft.com} \
    -messageStyle ::xosoap::RpcEncoded

# delete
# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /
#
JasperServerConsumer ad_proc -returns xsString\
    delete {
      -requestXmlString:xsString
    } {} {}

# get
# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /
#
JasperServerConsumer ad_proc -returns xsString\
    get {
      -requestXmlString:xsString
    } {} {}

# list
# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /
#
JasperServerConsumer ad_proc -returns xsString\
    list {
      -requestXmlString:xsString
    } {} {}

# put
# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /
#
JasperServerConsumer ad_proc -returns xsString\
    put {
      -requestXmlString:xsString
    } {} {}

# runReport
# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /
#
JasperServerConsumer ad_proc -returns xsString\
    runReport {
      -requestXmlString:xsString
    } {} {}

# sample invocation -> delete
# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /
#
set result [JasperServerConsumer delete \
    -requestXmlString "<request/>"]

ns_return 200 text/plain "JasperServerConsumer: Retrieved result '$result'"


