namespace eval ::prolix::pms {
  namespace import -force ::xorb::*
  # # # # # # # # # # # # # # # # # #	
  # # # # # # # # # # # # # # # # # #
  # # Scenario Prolix/PMS
  # # - Document/Literal style
  # # see http://www.whitemesa.com/interop/proposal2.html
  # # # # # # # # # # # # # # # # # #
  # # # # # # # # # # # # # # # # # #
  
  # / / / / / / / / / / / / / / / / /
  # Issues:
  # 

  # # # # # # # # # # # # # # # # # #	
  # # # # # # # # # # # # # # # # # #
  # # Types
  # # # # # # # # # # # # # # # # # #	
  # # # # # # # # # # # # # # # # # #

  # / / / / / / / / / / / / / / / / /
  # PMSService->createLearningActivity
  ::xotcl::Class Addresstype -slots {
    ::xorb::datatypes::AnyAttribute street -anyType xsString
    ::xorb::datatypes::AnyAttribute zip -anyType xsString
    ::xorb::datatypes::AnyAttribute city -anyType xsString
    ::xorb::datatypes::AnyAttribute state -anyType xsString
    ::xorb::datatypes::AnyAttribute phone -anyType xsString
    ::xorb::datatypes::AnyAttribute email -anyType xsString
    ::xorb::datatypes::AnyAttribute url -anyType xsString
  }
  ::xotcl::Class Scheduletype -slots {
    ::xorb::datatypes::AnyAttribute begin -anyType xsDateTime
    ::xorb::datatypes::AnyAttribute end -anyType xsDateTime
  }
  ::xotcl::Class CreateLearningActivityRequest -slots {
    ::xorb::datatypes::AnyAttribute learningActivityId -anyType xsString
    ::xorb::datatypes::AnyAttribute learningActivityTitle -anyType xsString
    ::xorb::datatypes::AnyAttribute description -anyType xsString
    ::xorb::datatypes::AnyAttribute location \
	-anyType soapStruct(::prolix::pms::Addresstype)
    ::xorb::datatypes::AnyAttribute schedule \
	-anyType soapStruct(::prolix::pms::Scheduletype)
    ::xorb::datatypes::AnyAttribute duration -anyType xsTime
  }
  ::xotcl::Class CreateLearningActivityResponse -slots {
    ::xorb::datatypes::AnyAttribute returnCode -anyType xsInt
    ::xorb::datatypes::AnyAttribute message -anyType xsString
  }
  # / / / / / / / / / / / / / / / / /
  # PMSService->updateLearningActivityRequest
  ::xotcl::Class UpdateLearningActivityRequest -slots {
    ::xorb::datatypes::AnyAttribute learningActivityId -anyType xsString
    ::xorb::datatypes::AnyAttribute learningActivityTitle -anyType xsString
    ::xorb::datatypes::AnyAttribute description -anyType xsString
    ::xorb::datatypes::AnyAttribute location \
	-anyType soapStruct(::prolix::pms::Addresstype)
    ::xorb::datatypes::AnyAttribute schedule \
	-anyType soapStruct(::prolix::pms::Scheduletype)
    ::xorb::datatypes::AnyAttribute duration -anyType xsTime
  }
  ::xotcl::Class UpdateLearningActivityResponse -slots {
    ::xorb::datatypes::AnyAttribute returnCode -anyType xsInt
    ::xorb::datatypes::AnyAttribute message -anyType xsString
  }
  # / / / / / / / / / / / / / / / / /
  # PMSService->deleteLearningActivityRequest
  ::xotcl::Class DeleteLearningActivityRequest -slots {
    ::xorb::datatypes::AnyAttribute learningActivityId -anyType xsString
  }
  ::xotcl::Class DeleteLearningActivityResponse -slots {
    ::xorb::datatypes::AnyAttribute returnCode -anyType xsInt
    ::xorb::datatypes::AnyAttribute message -anyType xsString
  }

  # / / / / / / / / / / / / / / / / /
  # PMSService->addParticipant
  ::xotcl::Class AddParticipantRequest -slots {
    ::xorb::datatypes::AnyAttribute learningActivityId -anyType xsString
    ::xorb::datatypes::AnyAttribute uid -anyType xsString
    ::xorb::datatypes::AnyAttribute role -anyType xsString
  }
  ::xotcl::Class AddParticipantResponse -slots {
    ::xorb::datatypes::AnyAttribute returnCode -anyType xsInt
    ::xorb::datatypes::AnyAttribute message -anyType xsString
  }
  # / / / / / / / / / / / / / / / / /
  # PMSService->removeParticipant
  ::xotcl::Class RemoveParticipantRequest -slots {
    ::xorb::datatypes::AnyAttribute learningActivityId -anyType xsString
    ::xorb::datatypes::AnyAttribute uid -anyType xsString
  }
  ::xotcl::Class RemoveParticipantResponse -slots {
    ::xorb::datatypes::AnyAttribute returnCode -anyType xsInt
    ::xorb::datatypes::AnyAttribute message -anyType xsString
  }

  

  ServiceContract PMSService -defines {
    ::xorb::Abstract createLearningActivity \
	-arguments {
	  parameters:soapStruct(::prolix::pms::CreateLearningActivityRequest)
	} -returns "parameters:soapStruct(::prolix::pms::CreateLearningActivityResponse)" \
	-description {
	  see http://www.prolixproject.org/ProlixMessages/xmlSchema/ProlixMessages.xsd
	}
        ::xorb::Abstract updateLearningActivity \
	-arguments {
	  parameters:soapStruct(::prolix::pms::UpdateLearningActivityRequest)
	} -returns "parameters:soapStruct(::prolix::pms::UpdateLearningActivityResponse)" \
	-description {
	  see http://www.prolixproject.org/ProlixMessages/xmlSchema/ProlixMessages.xsd
	}
    ::xorb::Abstract deleteLearningActivity \
	-arguments {
	  parameters:soapStruct(::prolix::pms::DeleteLearningActivityRequest)
	} -returns "parameters:soapStruct(::prolix::pms::DeleteLearningActivityResponse)" \
	-description {
	  see http://www.prolixproject.org/ProlixMessages/xmlSchema/ProlixMessages.xsd
	}
      ::xorb::Abstract addParticipant \
	-arguments {
	  parameters:soapStruct(::prolix::pms::AddParticipantRequest)
	} -returns "parameters:soapStruct(::prolix::pms::AddParticipantResponse)" \
	-description {
	  see http://www.prolixproject.org/ProlixMessages/xmlSchema/ProlixMessages.xsd
	}
    ::xorb::Abstract removeParticipant \
	-arguments {
	  parameters:soapStruct(::prolix::pms::RemoveParticipantRequest)
	} -returns "parameters:soapStruct(::prolix::pms::RemoveParticipantResponse)" \
	-description {
	  see http://www.prolixproject.org/ProlixMessages/xmlSchema/ProlixMessages.xsd
	}
  } -ad_doc {
    This contract realises the interface description
    of PMSService.
    see http://www.prolixproject.org/ProlixMessages/xmlSchema/ProlixMessages.xsd
  }

  ServiceImplementation PMSServiceImpl \
      -implements PMSService \
      -using {
	# / / / / / / / / / / / / /
	# createLearningActivity
	::xorb::Method createLearningActivity {
	  parameters:required
	} {A learning activity is created.} {
	  my log [self proc]=[$parameters serialize]
	  set response [CreateLearningActivityResponse new \
			    -returnCode -1 \
			    -message "[self proc] called"]
	  return $response
	}
	# / / / / / / / / / / / / /
	# updateLearningActivity
	::xorb::Method updateLearningActivity {
	  parameters:required
	} {A learning activity is updated.} {
	  my log [self proc]=[$parameters serialize]
	  set response [UpdateLearningActivityResponse new \
			    -returnCode -1 \
			    -message "[self proc] called"]
	  return $response
	}
	# / / / / / / / / / / / / /
	# deleteLearningActivity
	::xorb::Method deleteLearningActivity {
	  parameters:required
	} {A learning activity is deleted.} {
	  my log [self proc]=[$parameters serialize]
	  set response [DeleteLearningActivityResponse new \
			    -returnCode -1 \
			    -message "[self proc] called"]
	  return $response
	}
	# / / / / / / / / / / / / /
	# addParticipant
	::xorb::Method addParticipant {
	  parameters:required
	} {A participant is added.} {
	  my log [self proc]=[$parameters serialize]
	  set response [AddParticipantResponse new \
			    -returnCode -1 \
			    -message "[self proc] called"]
	  return $response
	}
	# / / / / / / / / / / / / /
	# removeParticipant
	::xorb::Method removeParticipant {
	  parameters:required
	} {A participant is removed.} {
	  my log [self proc]=[$parameters serialize]
	  set response [RemoveParticipantResponse new \
			    -returnCode -1 \
			    -message "[self proc] called"]
	  return $response
	}
      }
  
  # / / / / / / / / / / / /
  # deploy the 
  PMSServiceImpl deploy


}
