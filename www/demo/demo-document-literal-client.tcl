

set comment {
set payload(createCourse) {<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsd1="http://oacs-dotlrn-conf2007.wu-wien.ac.at/xosoap/services/PMSServiceImpl2/">
   <soap:Body>
      <xsd1:createCourseRequest>
         <header>
            <userId>4</userId>
            <timestamp>2007-05-24T20:29:33Z</timestamp>
            <receiver>erewr</receiver>
            <globalProcessId>werwe</globalProcessId>
            <sender>werw</sender>
            <messageId>wer</messageId>
            <messageType/>
         </header>
         <body>
            <description>re</description>
            <location>
               <email>ewr</email>
               <name>wer</name>
               <state>wer</state>
               <city>wer</city>
               <phone>wer</phone>
               <street>wer</street>
               <zip>wer</zip>
               <url>wer</url>
            </location>
            <schedule>
               <begin>2007-05-25T20:29:33Z</begin>
               <end>2007-05-26T20:29:33Z</end>
            </schedule>
            <duration>12:00:00</duration>
            <courseId>2</courseId>
            <courseTitle>DFSDFSD</courseTitle>
         </body>
      </xsd1:createCourseRequest>
   </soap:Body>
</soap:Envelope>}


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
}

set payload(createCourse) {<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsd1="http://oacs-dotlrn-conf2007.wu-wien.ac.at/xosoap/services/PMSServiceImpl2/">
   <soap:Body>
      <xsd1:createCourseRequest>
         <header>
            <userId>4</userId>
            <timestamp>2007-05-24T20:29:33Z</timestamp>
            <receiver>erewr</receiver>
            <globalProcessId>werwe</globalProcessId>
            <sender>werw</sender>
            <messageId>wer</messageId>
            <messageType>sdasdas</messageType>
         </header>
         <body>
            <description>re</description>
            <location>
               <email>emailValue</email>
               <name>MyNameValue</name>
               <state>StateValue</state>
               <city>CityValue</city>
               <phone>PhoneValue</phone>
               <street>StreetValue</street>
               <zip>ZipValue</zip>
               <url>UrlValue</url>
            </location>
            <schedule>
               <begin>2007-05-25T20:29:33Z</begin>
               <end>2007-05-26T20:29:33Z</end>
            </schedule>
            <duration>12:00:00</duration>
            <courseId>2</courseId>
            <courseTitle>DFSDFSD</courseTitle>
         </body>
      </xsd1:createCourseRequest>
   </soap:Body>
</soap:Envelope>}

set payload(addParticipant) {<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsd1="http://oacs-dotlrn-conf2007.wu-wien.ac.at/xosoap/services/PMSServiceImpl2/">
   <soap:Body>
      <xsd1:addParticipantRequest>
         <header>
            <userId>323</userId>
            <timestamp>2007-05-16T22:04:02Z</timestamp>
            <receiver>232</receiver>
            <globalProcessId>323</globalProcessId>
            <sender>232</sender>
            <messageId>232</messageId>
            <messageType>23</messageType>
         </header>
         <body>
            <courseId>2323</courseId>
            <uid>232</uid>
            <role>232</role>
         </body>
      </xsd1:addParticipantRequest>
   </soap:Body>
</soap:Envelope>}

ns_write <html><title></title><body>
foreach call [array names payload] {
  set url http://localhost:8000/xosoap/services/PMSServiceImpl2
  set r [::xo::HttpRequest new \
	     -content_type "text/xml" \
	     -url $url \
	     -post_data $payload($call) \
	     -request_header_fields [list SOAPAction $url/$call]]  
  ns_write <p>$call=<pre>[ad_quotehtml [$r set data]]</pre></p>
}
ns_write </body></html>