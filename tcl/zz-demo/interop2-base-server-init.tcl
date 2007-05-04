# # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # #
# # Demo scenario
# # Realising Interop2 Base test
# # suite
# # see http://www.whitemesa.com/interop/proposal2.html
# # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # #

namespace eval ::xosoap::demo {

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
    ::xorb::Abstract echoString \
	-arguments {
	  inputString:xsString
	} -returns "returnValue:xsString" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoString
	}
    ::xorb::Abstract echoInteger \
	-arguments {
	  inputInteger:xsInteger
	} -returns "returnValue:xsInteger" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoInteger
	}
    ::xorb::Abstract echoFloat \
	-arguments {
	  inputFloat:xsFloat
	} -returns "returnValue:xsFloat" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoFloat
	}
    ::xorb::Abstract echoVoid \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoVoid
	}
    ::xorb::Abstract echoBase64 \
	-arguments {
	  inputBase64:xsBase64Binary
	} -returns "returnValue:xsBase64Binary" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoBase64
	}
    ::xorb::Abstract echoHexBinary \
	-arguments {
	  inputHexBinary:xsHexBinary
	} -returns "returnValue:xsHexBinary" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoHexBinary
	}
    ::xorb::Abstract echoDate \
	-arguments {
	  inputDate:xsDateTime
	} -returns "returnValue:xsDateTime" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoDate
	}
    ::xorb::Abstract echoDecimal \
	-arguments {
	  inputDecimal:xsDecimal
	} -returns "returnValue:xsDecimal" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoDecimal
	}
    ::xorb::Abstract echoBoolean \
	-arguments {
	  inputBoolean:xsString
	} -returns "returnValue:xsBoolean" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoBoolean
	}

    ::xorb::Abstract echoStruct \
	-arguments {
	  inputStruct:soapStruct=::xosoap::demo::exampleStruct
	} -returns "returnValue:soapStruct=::xosoap::demo::exampleStruct" \
	-description {
	  see http://www.whitemesa.com/interop/proposal2.html#echoStruct
	}

  } -ad_doc {
    This contract provides the interface description
    for the Soap Interop2 Base test suite.
  }

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
	::xorb::Method echoString {
	  inputString:required
	} {Echoes an incoming string} {
	  my log "ECHOSTRING called: $inputString"
	  return $inputString
	}
	# / / / / / / / / / / / / /
	# echoInteger
	::xorb::Method echoInteger {
	  inputInteger:required
	} {Echoes an incoming integer} {
	  return $inputInteger
	}
	# / / / / / / / / / / / / /
	# echoInteger
	::xorb::Method echoFloat {
	  inputFloat:required
	} {Echoes an incoming float} {
	  return $inputFloat
	}
	# / / / / / / / / / / / / /
	# echoVoid
	::xorb::Method echoVoid {} {non-returning call:void} {
	  # do nothing
	}
	# / / / / / / / / / / / / /
	# echoBase64
	::xorb::Method echoBase64 {
	  inputBase64:required
	} {Echoes an incoming base64 string} {
	  return $inputBase64
	}
	# / / / / / / / / / / / / /
	# echoHexBinary
	::xorb::Method echoHexBinary {
	  inputHexBinary:required
	} {Echoes an incoming hex string} {
	  return $inputHexBinary
	}
	# / / / / / / / / / / / / /
	# echoDate
	::xorb::Method echoDate {
	  inputDate:required
	} {Echoes an incoming datetime value} {
	  return $inputDate
	}
	# / / / / / / / / / / / / /
	# echoDecimal
	::xorb::Method echoDecimal {
	  inputDecimal:required
	} {Echoes an incoming decimal value} {
	  return $inputDecimal
	}
	# / / / / / / / / / / / / /
	# echoBoolean
	::xorb::Method echoBoolean {
	  inputBoolean:required
	} {Echoes an incoming boolean value} {
	  return $inputBoolean
	}
	# / / / / / / / / / / / / /
	# echoStruct
	::xorb::Method echoStruct {
	  inputStruct:required
	} {Echoes an incoming struct} {
	  my log inputStruct(varFloat)=[$inputStruct varFloat]
	  return $inputStruct
	}
      }
  
  # / / / / / / / / / / / /
  # deployment descriptor
  # + actualy deployment

  SoapInterop2Impl deploy
  
}