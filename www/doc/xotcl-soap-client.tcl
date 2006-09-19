ad_page_contract {

      @author Stefan Sobernig
} {
    
}
	
	set html "<html><body>"
	
	::xotcl::Class instmixin ::xorb::client::InvocationProxy
	
	set s_new [::xorb::client::Stub new -bind SqiService1]
	$s_new ad_instproc synchronousQuery \
		{-queryStatement:i} \
		{test for local invoc} {}
	set c1 [$s_new new]
	
	append html "<div>[$c1 synchronousQuery -queryStatement "test"]</div>"
	
###############################################
	
	::xorb::client::Stub s -bind SqiService1
	s ad_instproc synchronousQuery \
		{-queryStatement:i} \
		{test for local invoc} {}
	set c1a [s new]
	append html "<div>[$c1a synchronousQuery -queryStatement "test"]</div>"
	
###############################################
	
	Class cc 
	cc ad_instproc -stub -bind SqiService1 \
		synchronousQuery \
		{-queryStatement:i} \
		{test for local invoc} {}
	
	append html "<div>[[cc new] synchronousQuery -queryStatement "test"]</div>"

###############################################
	
	set y [Class StockQuote]
		StockQuote ad_instproc \
		-stub \
		-bind soap://64.124.140.30:9090/soap \
		-uri "urn:xmethods-delayed-quotes" \
		getQuote \
		{-symbol:i} \
		{test for local invoc} {}
		
		set sqs [StockQuote new]
		
		append html "<div>[$sqs getQuote -symbol IBM]</div>"

###############################################

	::xorb::client::Stub StockQuoteStub -bind soap://64.124.140.30:9090/soap \
		-uri "urn:xmethods-delayed-quotes-dummy"
		
	StockQuoteStub ad_instproc \
		 -uri "urn:xmethods-delayed-quotes" \
		getQuote \
		{-symbol:i} \
		{test for local invoc} {}
		
		set sqs2 [StockQuoteStub new]
		
		append html "<div>[$sqs2 getQuote -symbol IBM]</div>"

###############################################
	
ns_return 200 text/html "$html</body></html>"
	
