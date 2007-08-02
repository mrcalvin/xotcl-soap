
namespace eval ::prolix::pms {
  
  
  Class CreateCourseRequest -slots {
    
    ::xorb::datatypes::AnyAttribute courseId -anyType XsString
    ::xorb::datatypes::AnyAttribute courseTitle -anyType XsString
    ::xorb::datatypes::AnyAttribute description -anyType XsString
    ::xorb::datatypes::AnyAttribute location \
	-anyType soapStruct(::prolix::pms::Addresstype)
    ::xorb::datatypes::AnyAttribute schedule \
	-anyType soapStruct(::prolix::pms::Scheduletype)
    ::xorb::datatypes::AnyAttribute duration -anyType XsTime
    
  }
  
  Class createCourseRequest -slots {
    ::xorb::datatypes::AnyAttribute header \
	-anyType soapStruct(::prolix::pms::messages::ProlixMessageHeader)
    ::xorb::datatypes::AnyAttribute body \
	-anyType soapStruct(::prolix::pms::CreateCourseRequest)
    
  }
  
  
  Class addParticipantResponse -slots {
    ::xorb::datatypes::AnyAttribute header \
	-anyType soapStruct(::prolix::pms::messages::ProlixMessageHeader)
    ::xorb::datatypes::AnyAttribute body \
	-anyType soapStruct(::prolix::pms::AddParticipantResponse)
  }
  
  
  
  Class AddParticipantResponse -slots {
    ::xorb::datatypes::AnyAttribute returnCode -anyType XsInt
    ::xorb::datatypes::AnyAttribute message -anyType XsString
  }
  
  
  
  Class Scheduletype -slots {
    ::xorb::datatypes::AnyAttribute begin -anyType XsDateTime
    ::xorb::datatypes::AnyAttribute end -anyType XsDateTime
  }
  
  Class updateCourseResponse -slots {
    ::xorb::datatypes::AnyAttribute header \
	-anyType soapStruct(::prolix::pms::messages::ProlixMessageHeader)
    ::xorb::datatypes::AnyAttribute body \
	-anyType soapStruct(::prolix::pms::UpdateCourseResponse)
    
  }

  Class UpdateCourseResponse -slots {
    ::xorb::datatypes::AnyAttribute returnCode -anyType XsInt
    ::xorb::datatypes::AnyAttribute message -anyType XsString
  }
  
  Class removeParticipantResponse -slots {
    ::xorb::datatypes::AnyAttribute header \
	-anyType soapStruct(::prolix::pms::messages::ProlixMessageHeader)
    ::xorb::datatypes::AnyAttribute body \
	-anyType soapStruct(::prolix::pms::RemoveParticipantResponse)
  }
  
  Class RemoveParticipantResponse -slots {
    ::xorb::datatypes::AnyAttribute returnCode -anyType XsInt
    ::xorb::datatypes::AnyAttribute message -anyType XsString
  }
  
  Class DeleteCourseRequest -slots {
    ::xorb::datatypes::AnyAttribute courseId -anyType XsString
  }
  
  Class deleteCourseRequest -slots {
    ::xorb::datatypes::AnyAttribute header \
	-anyType soapStruct(::prolix::pms::messages::ProlixMessageHeader)
    ::xorb::datatypes::AnyAttribute body \
	-anyType soapStruct(::prolix::pms::DeleteCourseRequest)
  }
  
  Class removeParticipantRequest -slots {
    ::xorb::datatypes::AnyAttribute header \
	-anyType soapStruct(::prolix::pms::messages::ProlixMessageHeader)
    ::xorb::datatypes::AnyAttribute body \
	-anyType soapStruct(::prolix::pms::RemoveParticipantRequest)
  }
  
  Class RemoveParticipantRequest -slots {
    ::xorb::datatypes::AnyAttribute courseId -anyType XsString
    ::xorb::datatypes::AnyAttribute uid -anyType XsString
  }
  
  Class Addresstype -slots {
    ::xorb::datatypes::AnyAttribute name -anyType XsString
    ::xorb::datatypes::AnyAttribute street -anyType XsString
    ::xorb::datatypes::AnyAttribute zip -anyType XsString
    ::xorb::datatypes::AnyAttribute city -anyType XsString
    ::xorb::datatypes::AnyAttribute state -anyType XsString
    ::xorb::datatypes::AnyAttribute phone -anyType XsString
    ::xorb::datatypes::AnyAttribute email -anyType XsString
    ::xorb::datatypes::AnyAttribute url -anyType XsString
  }
  
  
  
  Class addParticipantRequest -slots {
    ::xorb::datatypes::AnyAttribute header \
	-anyType soapStruct(::prolix::pms::messages::ProlixMessageHeader)
    ::xorb::datatypes::AnyAttribute body \
	-anyType soapStruct(::prolix::pms::AddParticipantRequest)
  }
  
  Class AddParticipantRequest -slots {
    ::xorb::datatypes::AnyAttribute courseId -anyType XsString
    ::xorb::datatypes::AnyAttribute uid -anyType XsString
    ::xorb::datatypes::AnyAttribute role -anyType XsString
  }
  
  
  
  Class DeleteCourseResponse -slots {
    ::xorb::datatypes::AnyAttribute returnCode -anyType XsInt
    ::xorb::datatypes::AnyAttribute message -anyType XsString
  }
  
  
  
  Class deleteCourseResponse -slots {
    ::xorb::datatypes::AnyAttribute header \
	-anyType soapStruct(::prolix::pms::messages::ProlixMessageHeader)
       ::xorb::datatypes::AnyAttribute body \
	-anyType soapStruct(::prolix::pms::DeleteCourseResponse)
  }
  
  Class CreateCourseResponse -slots {
    ::xorb::datatypes::AnyAttribute returnCode -anyType XsInt
    ::xorb::datatypes::AnyAttribute message -anyType XsString
  }
  
  
  
  Class createCourseResponse -slots {
    ::xorb::datatypes::AnyAttribute header \
	-anyType soapStruct(::prolix::pms::messages::ProlixMessageHeader)
    ::xorb::datatypes::AnyAttribute body \
	-anyType soapStruct(::prolix::pms::CreateCourseResponse)
  }
  
  Class updateCourseRequest -slots {
    ::xorb::datatypes::AnyAttribute header \
	-anyType soapStruct(::prolix::pms::messages::ProlixMessageHeader)
    ::xorb::datatypes::AnyAttribute body \
	-anyType soapStruct(::prolix::pms::UpdateCourseRequest)
  }
  
  Class UpdateCourseRequest -slots {
    
    ::xorb::datatypes::AnyAttribute courseId -anyType XsString
    ::xorb::datatypes::AnyAttribute courseTitle -anyType XsString
    ::xorb::datatypes::AnyAttribute decription -anyType XsString
    ::xorb::datatypes::AnyAttribute location \
	-anyType soapStruct(::prolix::pms::Addresstype)
    ::xorb::datatypes::AnyAttribute schedule \
	-anyType soapStruct(::prolix::pms::Scheduletype)
    ::xorb::datatypes::AnyAttribute duration -anyType XsTime
  }
} 

namespace eval ::prolix::pms::messages {
  
  
  Class ProlixMessageHeader -slots {
    ::xorb::datatypes::AnyAttribute messageId -anyType XsString
    ::xorb::datatypes::AnyAttribute globalProcessId -anyType XsString
    ::xorb::datatypes::AnyAttribute userId -anyType XsString
    ::xorb::datatypes::AnyAttribute timestamp -anyType XsDateTime
    ::xorb::datatypes::AnyAttribute messageType -anyType XsString
    ::xorb::datatypes::AnyAttribute sender -anyType XsString
    ::xorb::datatypes::AnyAttribute receiver -anyType XsString
  }
  
} 

namespace eval ::prolix::pms {
  namespace import ::xorb::*
  ServiceContract PMSService2 -defines {
    
    ::xorb::Abstract createCourse  \
	-arguments parameters:soapStruct(::prolix::pms::createCourseRequest)  \
	-returns parameters:soapStruct(::prolix::pms::createCourseResponse) \
	-description {Creating a course.}
    
    ::xorb::Abstract deleteCourse  \
	-arguments parameters:soapStruct(::prolix::pms::deleteCourseRequest) \
	-returns parameters:soapStruct(::prolix::pms::deleteCourseResponse) \
	-description {Deleting a course.}
    
    ::xorb::Abstract updateCourse  \
	-arguments parameters:soapStruct(::prolix::pms::updateCourseRequest) \
	-returns parameters:soapStruct(::prolix::pms::updateCourseResponse) \
	-description {Updating a course.}
	
    ::xorb::Abstract addParticipant  \
	-arguments parameters:soapStruct(::prolix::pms::addParticipantRequest) \
	-returns parameters:soapStruct(::prolix::pms::addParticipantResponse) \
	-description {Adding a participant.}
    
    ::xorb::Abstract removeParticipant  \
	-arguments parameters:soapStruct(::prolix::pms::removeParticipantRequest)  \
	-returns parameters:soapStruct(::prolix::pms::removeParticipantResponse) \
	-description {Removing a participant.}
  } -ad_doc { 
    This contract defines a newer version of the Prolix/PMS interface 
    description
  } 

  #PMSService2 deploy

  ::prolix::pms::messages::ProlixMessageHeader header \
      -messageId -1 \
      -globalProcessId -1 \
      -userId -1 \
      -timestamp 2007-05-17T17:31:10Z \
      -messageType dummy \
      -sender Alice \
      -receiver Bob
  
  ServiceImplementation PMSServiceImpl2 \
      -implements PMSService2 \
      -using {
	# / / / / / / / / / / / / /
	# createCourseActivity
	::xorb::Method createCourse {
	  -parameters:required
	} {A learning activity is created.} {
	  my log [self proc]=[$parameters serialize]
	  set body [CreateCourseResponse new \
			-returnCode -1 \
			-message "[self proc] called"]
	  set response [createCourseResponse new \
			    -header ::prolix::pms::header \
			    -body $body]
	  return $response
	}
	# / / / / / / / / / / / / /
	# updateCourseActivity
	::xorb::Method updateCourse {
	  -parameters:required
	} {A learning activity is updated.} {
	  my log [self proc]=[$parameters serialize]
	  set body [UpdatCourseResponse new \
			    -returnCode -1 \
			    -message "[self proc] called"]
	  set response [updateCourseResponse new \
			   -header ::prolix::pms::header \
			   -body $body]
	  return $response
	}
	# / / / / / / / / / / / / /
	# deleteCourseActivity
	::xorb::Method deleteCourse {
	  -parameters:required
	} {A learning activity is deleted.} {
	  my log [self proc]=[$parameters serialize]
	  set body [DeleteCourseResponse new \
			    -returnCode -1 \
			    -message "[self proc] called"]
	  set response [deleteCourseResponse new \
			   -header ::prolix::pms::header \
			   -body $body]
	  return $response
	}
	# / / / / / / / / / / / / /
	# addParticipant
	::xorb::Method addParticipant {
	  -parameters:required
	} {A participant is added.} {
	  my log [self proc]=[$parameters serialize]
	  set body [AddParticipantResponse new \
			    -returnCode -1 \
			    -message "[self proc] called"]
	  set response [addParticipantResponse new \
		  -header ::prolix::pms::header \
		  -body $body]
	  return $response
	}
	# / / / / / / / / / / / / /
	# removeParticipant
	::xorb::Method removeParticipant {
	  -parameters:required
	} {A participant is removed.} {
	  my log [self proc]=[$parameters serialize]
	  set body [RemoveParticipantResponse new \
			    -returnCode -1 \
			    -message "[self proc] called"]
	  set response [removeParticipantResponse new \
			   -header ::prolix::pms::header \
			   -body $body]
	  return $response
	}
      }
  
  # / / / / / / / / / / / /
  # deploy the 
  #PMSServiceImpl2 deploy
}