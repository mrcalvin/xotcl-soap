

set comment {
set payload(createLearningActivity) {<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:pms="http://www.prolixproject.org/PMSService/" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
   <soap:Body>
      <pms:createLearningActivityRequest>
         <learningActivityId>1234</learningActivityId>
         <learningActivityTitle>course</learningActivityTitle>
         <description>klklkk</description>
         <location>
            <name>org</name>
            <street>street</street>
            <zip>zip</zip>
            <city>city</city>
            <state>state</state>
            <phone>phone</phone>
            <email>email</email>
            <url>url</url>
         </location>
         <schedule>
            <begin>2007-05-14T09:01:49Z</begin>
            <end>2007-05-21T09:01:49Z</end>
         </schedule>
         <duration>12:00:00</duration>
      </pms:createLearningActivityRequest>
   </soap:Body>
</soap:Envelope>}
}

set payload(createLearningActivity) {<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsd1="http://oacs-dotlrn-conf2007.wu-wien.ac.at:8000/xosoap/services/PMSServiceImpl/">
   <soap:Body>
      <xsd1:CreateLearningActivityRequest>
         <description>k</description>
         <location>
            <email>lk</email>
            <state>klk</state>
            <city>lk</city>
            <phone>lk</phone>
            <street>lk</street>
            <zip>klk</zip>
            <url>klk</url>
         </location>
         <schedule>
            <begin>2007-05-16T02:04:53Z</begin>
            <end>2007-05-17T02:04:53Z</end>
         </schedule>
         <learningActivityId>lk</learningActivityId>
         <duration>12:00:00</duration>
         <learningActivityTitle>klk</learningActivityTitle>
      </xsd1:CreateLearningActivityRequest>
   </soap:Body>
</soap:Envelope>}

set payload(deleteLearningActivity) {<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:pms="http://www.prolixproject.org/PMSService/" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
   <soap:Body>
      <pms:deleteLearningActivityRequest>
         <learningActivityId>1</learningActivityId>
      </pms:deleteLearningActivityRequest>
   </soap:Body>
</soap:Envelope>}

set payload(updateLearningActivity) {<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:pms="http://www.prolixproject.org/PMSService/" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
   <soap:Body>
      <pms:updateLearningActivityRequest>
         <learningActivityId>123</learningActivityId>
         <learningActivityTitle>title</learningActivityTitle>
         <description>desc</description>
         <location>
            <name>org</name>
            <street>street</street>
            <zip>zip</zip>
            <city>city</city>
            <state>state</state>
            <phone>phone</phone>
            <email>email</email>
            <url>url</url>
         </location>
         <schedule>
            <begin>2007-05-14T09:07:45Z</begin>
            <end>2007-05-29T09:07:45Z</end>
         </schedule>
         <duration>12:00:00</duration>
      </pms:updateLearningActivityRequest>
   </soap:Body>
</soap:Envelope>}

set payload(addParticipant) {<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:pms="http://www.prolixproject.org/PMSService/" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
   <soap:Body>
      <pms:addParticipantRequest>
         <learningActivityId>123</learningActivityId>
         <uid>1</uid>
         <role>destroyer</role>
      </pms:addParticipantRequest>
   </soap:Body>
</soap:Envelope>}

set payload(removeParticipant) {<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:pms="http://www.prolixproject.org/PMSService/" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
   <soap:Body>
      <pms:removeParticipantRequest>
         <learningActivityId>123</learningActivityId>
         <uid>1345</uid>
      </pms:removeParticipantRequest>
   </soap:Body>
</soap:Envelope>}

ns_write <html><title></title><body>
foreach call [array names payload] {
  set url http://openacs-dotlrn.wu-wien.ac.at:8000/xosoap/services/PMSServiceImpl
  set r [::xo::HttpRequest new \
	     -content_type "text/xml" \
	     -url $url \
	     -post_data $payload($call) \
	     -request_header_fields [list SOAPAction $url/$call]]  
  ns_write <p>$call=<pre>[ad_quotehtml [$r set data]]</pre></p>
}
ns_write </body></html>