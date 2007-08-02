namespace eval ::xosoap::demo {

  # # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # # #
  # # Demo scenario
  # # Realising Interop2 Base test
  # # suite
  # # see http://www.whitemesa.com/interop/proposal2.html
  # # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # # #
  
  namespace import -force ::xorb::*

  # / / / / / / / / / / / / / / / / / /
  # Staging
  # - defining complex types used

  Class exampleStruct -slots {
    ::xorb::datatypes::AnyAttribute varString -anyType ::xosoap::xsd::XsString
    ::xorb::datatypes::AnyAttribute varInt -anyType ::xosoap::xsd::XsInteger
    ::xorb::datatypes::AnyAttribute varFloat -anyType ::xosoap::xsd::XsFloat
  }

   #     ___________________
  #   ,'                   `.
  #  /                       \
  # |  2) New contract:       |
  # |     SoapInterop2        |
  #  \                       /
  #   `._______   _________,'
  #           / ,'
  #          /,'
  #         /'
  # / / / / / / / / / / / / / / / / / / / /
  # - 	Declaring a new contract
  # - 	Involves a contract specification object
  # -	Argument declaration allows all data types
  #	available in acs_datatypes, and is extended
  #	by plug-ins (xosoap -> xs data types)
 
  ServiceContract SoapInterop2  -defines {
    Abstract echoString \
	-arguments {
	  inputString:xsString
	} -returns "returnValue:xsString" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoString
	}
    Abstract echoInteger \
	-arguments {
	  inputInteger:xsInteger
	} -returns "returnValue:xsInteger" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoInteger
	}
    Abstract echoFloat \
	-arguments {
	  inputFloat:xsFloat
	} -returns "returnValue:xsFloat" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoFloat
	}
    Abstract echoVoid \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoVoid
	}
    Abstract echoBase64 \
	-arguments {
	  inputBase64:xsBase64Binary
	} -returns "returnValue:xsBase64Binary" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoBase64
	}
    Abstract echoHexBinary \
	-arguments {
	  inputHexBinary:xsHexBinary
	} -returns "returnValue:xsHexBinary" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoHexBinary
	}
    Abstract echoDate \
	-arguments {
	  inputDate:xsDateTime
	} -returns "returnValue:xsDateTime" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoDate
	}
    Abstract echoDecimal \
	-arguments {
	  inputDecimal:xsDecimal
	} -returns "returnValue:xsDecimal" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoDecimal
	}
    Abstract echoBoolean \
	-arguments {
	  inputBoolean:xsString
	} -returns "returnValue:xsBoolean" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoBoolean
	}

    Abstract echoStruct \
	-arguments {
	  inputStruct:soapStruct(::xosoap::demo::exampleStruct)
	} -returns "returnValue:soapStruct(::xosoap::demo::exampleStruct)" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoStruct
	}
    Abstract echoStringArray \
	-arguments {
	  inputStringArray:soapArray(xsString)<2>
	} -returns "returnValue:soapArray(xsString)<2>" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoStringArray
	}
    Abstract echoIntegerArray \
	-arguments {
	  inputIntegerArray:soapArray(xsInteger)<2>
	} -returns "returnValue:soapArray(xsInteger)<2>" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoIntegerArray
	}
    Abstract echoFloatArray \
	-arguments {
	  inputFloatArray:soapArray(xsFloat)<2>
	} -returns "returnValue:soapArray(xsFloat)<2>" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoFloatArray
	}
    Abstract echoStructArray \
	-arguments {
	  inputStructArray:soapArray(soapStruct(xosoap::demo::exampleStruct))<2>
	} -returns "returnValue:soapArray(soapStruct(xosoap::demo::exampleStruct))<2>" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoStructArray
	}
  } -ad_doc {
    This contract provides the interface description
    for the Soap Interop2 Base test suite.
  } 

  SoapInterop2 deploy

   #     ___________________
  #   ,'                   `.
  #  /                       \
  # |  2) Implementation      |
  # |   for SoapInterop2      |
  #  \                       /
  #   `._______   _________,'
  #           / ,'
  #          /,'
  #         /'
  # / / / / / / / / / / / / / / / / / / / /
  # - 	It is possible to declare the 
  #	specification object as servant object,
  #	by means of the Method attribute slot


  ServiceImplementation SoapInterop2Impl \
      -implements SoapInterop2 \
      -using {
	# / / / / / / / / / / / / /
	# echoString
	Method echoString {
	  -inputString:required
	} {Echoes an incoming string} {
	  my log "ECHOSTRING called: $inputString"
	  return $inputString
	}
	# / / / / / / / / / / / / /
	# echoInteger
	Method echoInteger {
	  -inputInteger:required
	} {Echoes an incoming integer} {
	  return $inputInteger
	}
	# / / / / / / / / / / / / /
	# echoInteger
	Method echoFloat {
	  -inputFloat:required
	} {Echoes an incoming float} {
	  return $inputFloat
	}
	# / / / / / / / / / / / / /
	# echoVoid
	Method echoVoid {} {non-returning call:void} {
	  # do nothing
	}
	# / / / / / / / / / / / / /
	# echoBase64
	Method echoBase64 {
	  -inputBase64:required
	} {Echoes an incoming base64 string} {
	  return $inputBase64
	}
	# / / / / / / / / / / / / /
	# echoHexBinary
	Method echoHexBinary {
	  -inputHexBinary:required
	} {Echoes an incoming hex string} {
	  return $inputHexBinary
	}
	# / / / / / / / / / / / / /
	# echoDate
	Method echoDate {
	  -inputDate:required
	} {Echoes an incoming datetime value} {
	  return $inputDate
	}
	# / / / / / / / / / / / / /
	# echoDecimal
	Method echoDecimal {
	  -inputDecimal:required
	} {Echoes an incoming decimal value} {
	  return $inputDecimal
	}
	# / / / / / / / / / / / / /
	# echoBoolean
	Method echoBoolean {
	  -inputBoolean:required
	} {Echoes an incoming boolean value} {
	  return $inputBoolean
	}
	# / / / / / / / / / / / / /
	# echoStruct
	Method echoStruct {
	  -inputStruct:required
	} {Echoes an incoming struct} {
	  my log inputStruct(varFloat)=[$inputStruct varFloat]
	  return $inputStruct
	}
	# / / / / / / / / / / / / /
	# echoStringArray
	Method echoStringArray {
	  -inputStringArray:required
	} {Echoes an incoming array of strings} {
	  return $inputStringArray
	}
	# / / / / / / / / / / / / /
	# echoIntegerArray
	Method echoIntegerArray {
	  -inputIntegerArray:required
	} {Echoes an incoming array of integers} {
	  return $inputIntegerArray
	}
	# / / / / / / / / / / / / /
	# echoFloatArray
	Method echoFloatArray {
	  -inputFloatArray:required
	} {Echoes an incoming array of floats} {
	  return $inputFloatArray
	}
	# / / / / / / / / / / / / /
	# echoStructArray
	Method echoStructArray {
	  -inputStructArray:required
	} {Echoes an incoming array of structs} {
	  return $inputStructArray
	}
      }
  
  # / / / / / / / / / / / /
  # deployment descriptor
  # + actual deployment

  SoapInterop2Impl deploy
  
  # # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # # #
  # # Demo scenario
  # # Realising Soap Interop2 Group 'B' tests
  # # suite
  # # see http://www.whitemesa.com/interop/proposalB.html
  # # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # # #

  Class nestedStruct -slots {
    ::xorb::datatypes::AnyAttribute varString -anyType ::xosoap::xsd::XsString
    ::xorb::datatypes::AnyAttribute varInt -anyType ::xosoap::xsd::XsInteger
    ::xorb::datatypes::AnyAttribute varFloat -anyType ::xosoap::xsd::XsFloat
  }

  Class exampleNestingStruct -slots {
    ::xorb::datatypes::AnyAttribute varString -anyType ::xosoap::xsd::XsString
    ::xorb::datatypes::AnyAttribute varInt -anyType ::xosoap::xsd::XsInteger
    ::xorb::datatypes::AnyAttribute varFloat -anyType ::xosoap::xsd::XsFloat
    ::xorb::datatypes::AnyAttribute varStruct -anyType soapStruct(::xosoap::demo::nestedStruct)
  }

  Class nestedArrayStruct -slots {
    ::xorb::datatypes::AnyAttribute varString -anyType ::xosoap::xsd::XsString
    ::xorb::datatypes::AnyAttribute varInt -anyType ::xosoap::xsd::XsInteger
    ::xorb::datatypes::AnyAttribute varFloat -anyType ::xosoap::xsd::XsFloat
    ::xorb::datatypes::AnyAttribute varArray -anyType soapArray(xsString)<3>
  }

  ServiceContract SoapInterop2GroupB -defines {
    Abstract echoNestedStruct \
	-arguments {
	  inputStruct:soapStruct(::xosoap::demo::exampleNestingStruct)
	} -returns "returnValue:soapStruct(::xosoap::demo::exampleNestingStruct)" \
	-description {
	  see http://www.whitemesa.com/interop/proposalB.html#echoNestedStruct
	}
    Abstract echoNestedArray \
	-arguments {
	  inputStruct:soapStruct(::xosoap::demo::nestedArrayStruct)
	} -returns "returnValue:soapStruct(xosoap::demo::nestedArrayStruct)" \
	-description {
	  see http://www.whitemesa.com/interop/proposalB.html#echoNestedArray
	}
  } -ad_doc {
    This contract represents the interface description for the
    Whitemesa Soap Interop2 Group 'B' test suite.
  }

  SoapInterop2GroupB deploy

  ServiceImplementation SoapInterop2GroupBImpl \
      -implements SoapInterop2GroupB \
      -using {
	# / / / / / / / / / / / / /
	# echoNestedStruct
	Method echoNestedStruct {
	  -inputStruct:required
	} {Echoes an incoming nested structure of structs} {
	  return $inputStruct
	}
	# / / / / / / / / / / / / /
	# echoNestedArray
	Method echoNestedArray {
	  -inputStruct:required
	} {Echoes an incoming struct with a nested array} {
	  return $inputStruct
	}
      }
  
  # / / / / / / / / / / / /
  # deploy the 
  SoapInterop2GroupBImpl deploy
}
