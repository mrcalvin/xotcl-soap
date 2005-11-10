ad_library {
   
    <p>Library providing facilities for organising the lifecycle of servant objects of type <a href='/xotcl/show-object?object=::xosoap::Service'>::xosoap::Service</a>. The driving idea is to decouple the object/ target of invocation and the actual servant who serves the invocation in order to realise different lifetime scenarios for servant objects with respect to optimising resource usage and response times. This is achieved by the following components:</p>
    <p>
    <ul>
    <li>Lifecycle strategies: When creating a new service, a specific lifecycle strategy can be adopted for the concrete servant object(s) to be created upon invocation: The optional strategies include <a href='/xotcl/show-object?object=::xosoap::lifecycle::PerRequestStrategy'>per-request instances</a> and <a href='/xotcl/show-object?object=::xosoap::lifecycle::StaticInstanceStrategy'>static instances</a>. These differ with respect to scope or lifetime:  <a href='/xotcl/show-object?object=::xosoap::lifecycle::PerRequestStrategy'>per-request instances</a> are only created for the scope of single connections (or connection threads) while <a href='/xotcl/show-object?object=::xosoap::lifecycle::StaticInstanceStrategy'>static instances</a> remain alive for the entire runtime of OACS/AOLServer. The stragies implement different manners of resource management: The <a href='/xotcl/show-object?object=::xosoap::lifecycle::PerRequestStrategy'>per-request strategy</a> provides for basic pooling, <a href='/xotcl/show-object?object=::xosoap::lifecycle::StaticInstanceStrategy'>static instances</a> are lazily acquired.</li>	
    	
    	<li>Managing lifecyles: Each service is assigned a <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager'>::xosoap::lifecycle::LifecycleManager</a> that is informed upon invoking the affiliated servant object. This allows for some activation/deactivation of servant objects according to a <a href='/xotcl/show-object?object=::xosoap::lifecycle::AbstractLifecycleStrategy'>lifecycle strategy</a> that is encapuslated in the <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager'>lifecycle manager</a>. <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager'>Lifecycle managers</a> take also care of strategy-specific registering of services. </li>    	    	
    	<li>The aforementioned decoupling is realised in the following way: Each service is registered in the Invoker's ServiceRegistry as a tuple containing service name and the absolute reference of a <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::ServantProxy'>servant proxy</a>. All invocation tasks are directed towards this <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::ServantProxy'>servant proxy</a>. The <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager'>lifecycle managers</a> are registered and aligned to unique servant object ids in the <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManagerRegistry'>::xosoap::lifecycle::LifecycleManagerRegistry</a> that is equally attached to the Invoker. Upon invocation, the <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::ServantProxy'>servant proxy</a> retrieves the <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager'>lifecycle manager</a> in charge and redirects the call to a servant object activated and returned by this <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager'>lifecycle manager</a>.
    	</li>   	   	
    </ul>
    </p>
    

    @author stefan.sobernig@wu-wien.ac.at
    @creation-date October, 17 2005
    @cvs-id $Id$

  
}



namespace eval xosoap::lifecycle {

####################################################
# 	Lifecycle Manager
####################################################

::xotcl::Class LifecycleManager -parameter {{strategy -Class AbstractLifecycleStrategy -default 1}} -ad_doc {

<p>A life cycle manager provides methods for notification upon reception of an invocation task (see <a href='/api-doc/proc-view?proc=::xosoap::lifecyle::LifecycleManager+instproc+invocationDisembarked'>invocationDisembarked</a>) and upon termination of invocations (see <a href='/api-doc/proc-view?proc=::xosoap::lifecyle::LifecyleManager+instproc+invocationEmbarked'>invocationEmbarked</a>).
It encapsulates concrete lifecycle strategies of type <a href='/xotcl/show-object?object=::xosoap::lifecycle::AbstractLifecycleStrategy'>AbstractLifecycleStrategy</a> for the servant objects to be managed.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005

}

LifecycleManager ad_instproc invocationDisembarked {} {

		<p>The method is called by a <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::ServantProxy'>servant proxy</a> upon arrival of an invocation call. It returns a concrete servant object to handle the call.</p>

		@author stefan.sobernig@wu-wien.ac.at
		@creation-date October, 17 2005
		
		@return An concrete servant object (see <a href='/xotcl/show-object?object=::xosoap::Service'>Service</a>) as selected by the underlying, strategy-specific activation routine.
		
		@see <a href='/api-doc/proc-view?proc=::xosoap::lifecyle::ServantProxy+instproc+delegate'>::xosoap::lifecyle::ServantProxy delegate</a>
		@see <a href='/api-doc/proc-view?proc=::xosoap::lifecyle::AbstractLifecycleStrategy+instproc+activate'>::xosoap::lifecyle::AbstractLifecycleStrategy activate</a>

} {

	return [[my strategy] activate]

}
LifecycleManager ad_instproc invocationEmbarked {servant} {

		
		<p>Upon termination of an invocation, a <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::ServantProxy'>servant proxy</a> calls this method for deactivating the servant object according to strategy specifics.</p>
		
		@author stefan.sobernig@wu-wien.ac.at
		@creation-date October, 17 2005 
		
		@param servant An absolute reference to the servant object that just finished handling an invocation.
		
		@see <a href='/api-doc/proc-view?proc=::xosoap::lifecyle::ServantProxy+instproc+delegate'>::xosoap::lifecyle::ServantProxy delegate</a>
		@see <a href='/api-doc/proc-view?proc=::xosoap::lifecyle::AbstractLifecycleStrategy+instproc+deactivate'>::xosoap::lifecyle::AbstractLifecycleStrategy deactivate</a>

} {
	
	[my strategy] deactivate $servant
}


LifecycleManager ad_instproc register {objectID target} {

	<p>Registration at the level of the LifecycleManager refers to (1) populating the embedded strategy object with necessary infos (absolute reference of the newly created service class) and (2) calling the respective strategy's registration routine.</p>
	
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005 
	
	@param objectID The unique object id created by the invoker upon early registration.
	@param target An absolute reference to the type/ class of the newly created	<a href='/xotcl/show-object?object=::xosoap::Service'>service</a>.
	
	@return A <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::ServantProxy'>servant proxy</a> for the service just registered.


} {

	[my strategy] parent [self]
	# pass type info to strategy
	[my strategy] type $target	
	
	# strategy specific registeration
	return [[my strategy] register $objectID]
	}
	

####################################################
# 	Lifecycle Strategies
####################################################

::xotcl::Class::Parameter AbstractLifecycleStrategy -parameter {type parent} -ad_doc {

	<p>Provides a generic interface for concrete lifecycle strategies, such as <a href='/xotcl/show-object?object=::xosoap::lifecycle::PerRequestStrategy'>::xosoap::lifecycle::PerRequestStrategy</a> and <a href='/xotcl/show-object?object=::xosoap::lifecycle::StaticInstanceStrategy'>::xosoap::lifecycle::StaticInstanceStrategy</a></p>
	
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005 


}
AbstractLifecycleStrategy abstract instproc activate {}
AbstractLifecycleStrategy abstract instproc deactivate {}
AbstractLifecycleStrategy abstract instproc register {objectID}

::xotcl::Class::Parameter PerRequestStrategy -superclass AbstractLifecycleStrategy -ad_doc {

	<p>The per-request strategy allows the provision of stateless services, i.e. states of servant objects
	are only preserved for the lifetime of a connection (thread). Per-request instances in xoSoap come in a pooled flavour, i.e.
	instances are not repeatedly created and destroyed but a pool of instances is created upon registration of service and their
	state is cleared after invocation (see <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::TypedPuddleOfInstances'>::xosoap::lifecycle::LifecycleManager::TypedPuddleOfInstances</a>).</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005 	

}

PerRequestStrategy ad_instproc activate {} {

	<p>Activation refers to (1) selecting and returning an idle servant object and (2) invoking its constructor method in order
	to activate the initial / pre-defined state.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005 
	
	@return An idle servant object (see <a href='/xotcl/show-object?object=::xosoap::Service'>Service</a>) as retrieved from the pool of servants.

} {
	
	my instvar parent 
	set refPool "$parent"
	append refPool "::" "pool"
	
	#my log "[self]: [$refPool info class]"
	
	set idleServant [eval $refPool getIdleServant]
	
	# activate servant
	eval $idleServant init
	
	return $idleServant

}

PerRequestStrategy ad_instproc deactivate {servant} {

	<p>Deactivation refers to clearing the current state of the servant object that will be returned into
	in pool of idle servants. This is actually handled by the <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::TypedPuddleOfInstances'>::xosoap::lifecycle::LifecycleManager::TypedPuddleOfInstances</a>.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005 
	
	@param servant An absolute reference to the servant object that just finished handling an invocation.
	
	@see <a href='/api-doc/proc-view?proc=::xosoap::lifecycle::LifecycleManager::TypedPuddleOfInstances+instproc+putBack'>::xosoap::lifecycle::LifecycleManager::TypedPuddleOfInstances putBack</a>

} {

	my instvar parent
	set refPool "$parent"
	append refPool "::" "pool"
	eval $refPool putBack $servant

}

PerRequestStrategy ad_instproc register {objectID} {

	<p>Registration involves the creation and nesting of a <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::TypedPuddleOfInstances'>servant pool</a> in the lifecycle manager object. Finally,
	a <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::ServantProxy'>servant proxy</a> is instantiated and returned. The unique object id of the newly created service is attributed to this proxy object. This allows to resolve the appropriate <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager'>lifecycle manager</a> upon preparation of a pending invocation.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005 
	
	@param objectID The unique object id created by the invoker upon early registration.
	
	@return A <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::ServantProxy'>servant proxy</a> for the service just registered.

} {

	my instvar type parent
	set refPool "$parent"
	append refPool "::" "pool"
	
	eval LifecycleManager::TypedPuddleOfInstances $refPool -type $type -number 3
	my debug "[$refPool info class]: [$refPool info commands]"
	set refProxy "$parent"
	append refProxy "::" "proxy"
	# create proxy
	return [eval LifecycleManager::ServantProxy $refProxy -objectID $objectID] 
}

::xotcl::Class::Parameter StaticInstanceStrategy -superclass AbstractLifecycleStrategy -ad_doc {

	<p>Static servant instances allow for the provision of stateful services, i.e. the servant object states are preserved beyond the scope of connections (connection threads). Regarding resource consumption, static services are not created on startup of OACS/AOLServer but upon first invocation. This is also known as "lazy acquisition".</p>
	
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005 	

}

StaticInstanceStrategy ad_instproc register {objectID} {

	<p>In contrast to <a href='/xotcl/show-object?object=::xosoap::lifecycle::PerRequestStrategy'>::xosoap::lifecycle::PerRequestStrategy</a>, registration involves only the creation of
	a <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::ServantProxy'>servant proxy</a> that is returned to be registered. The unique object id of the newly created service is attributed to this proxy object. This allows to resolve the appropriate <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager'>lifecycle manager</a> upon preparation of a pending invocation.</p>
	
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005 
	
	@param objectID The unique object id created by the invoker upon early registration.
	
	@return A <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::ServantProxy'>servant proxy</a> for the service just registered.

} {

	# a strategy of static instances in a lazy-acquisition flavour only requires the creation of a shadowing proxy
	my instvar parent
	
	set refProxy "$parent"
	append refProxy "::" "proxy"
	# create proxy
	return [eval LifecycleManager::ServantProxy $refProxy -objectID $objectID] 
}

StaticInstanceStrategy ad_instproc activate {} {

	<p>Activation here implements the Lazy Acquisition pattern, i.e. first it is verified that the servant does not exist, if not
	it is instantiated and nested into the current <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager'>lifecycle manager</a>.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005 
	
	@return The static servant object (see <a href='/xotcl/show-object?object=::xosoap::Service'>Service</a>).


} {
	
	my instvar parent type
	
	# check for existing servant child, otherwise create (lazy acquisition)
	set staticExists 0
	foreach i [eval $parent info children] {
	
		if { [eval $i istype $type]  } {
		
			set staticExists 1
			break
		
		}
	
	}	
	
	set refStatic "$parent"
	append refStatic "::" "static"
	
	if {!$staticExists} {
	
		# create static servant for the first time (lazy acquisition)
		
		eval $type $refStatic
	
	} 
	
	# no specific per-request initialization, just return unmodified static servant
	return $refStatic
	
	

}

StaticInstanceStrategy ad_instproc deactivate {servant} {

	<p>The current realisation of the static-instance strategy does not enforce any post-invocation
	handling of the static instance in question.</p> 	

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005 
	
	@param servant An absolute reference to the static servant object that just finished handling an invocation.


} {

	# no post-invocation handling 

}

####################################################
# 	Servant proxy 
####################################################

::xotcl::Class LifecycleManager::ServantProxy -parameter {objectID} -ad_doc {

	<p>This class plays a crucial role for decoupling the invocation and the service of invocation tasks. It acts as intermediate
	between the Invoker and the actual servant object. This is realized by means of one of XOTcl's interception techniques: method filtering. The filter method <a href='/api-doc/proc-view?proc=::xosoap::lifecyle::ServantProxy+instproc+delegate'>::xosoap::lifecyle::ServantProxy delegate</a> intercepts any method call on the proxy object and redirects them to the actual <a href='/xotcl/show-object?object=::xosoap::Service'>servant object</a> that is returned by the previously identified <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager'>lifecycle manager</a>. Redirection/ forwarding is only provided if the targeted service method is not declared "hoarded".</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005 

}
LifecycleManager::ServantProxy ad_instproc delegate args {

	<p>The actual filter method for forwarding calls on the proxy to the identified servant object.
	It is registered as filter upon instantiation of the proxy.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005 
	
	@param args The arguments passed to the orginally called method. Subject to forwarding.
	
	@return Result of invocation, the return value of the actually invoked method on the servant object.
	
	@see <a href='/api-doc/proc-view?proc=::xosoap::lifecycle::LifecycleManager::ServantProxy+instproc+init'>::xosoap::lifecycle::LifecycleManager::ServantProxy init</a>


} {

	set cp [self calledproc]
      if { [string equal $cp objectID] || [string equal $cp filter] } {
        next
      } else {
      
      	# get Lifecycle Manager from Registry
      	set manager [::xosoap::InvokerThread do ConcreteInvoker::LCMRegistry get [my objectID]]
      	# notify Manager
      	#my log "[self]: gets $manager"
      	set shadowedObj [$manager invocationDisembarked]      
      	# forward call to shadowed object, provided that it is not explicitly declared "hoarded"
      	
     if {![[$shadowedObj info class] exists hoard] || ([[$shadowedObj info class] exists hoard] && ([string equal [[$shadowedObj info class] hoard] ""] || [expr { [lsearch  [[$shadowedObj info class] hoard] $cp] eq "-1" }]))} {
     		#my log "Arguments passed: $args"
        	set result [eval $shadowedObj $cp $args]
        	$manager invocationEmbarked $shadowedObj
        	return $result
        } else {
        
        #provide exception/ fault
        
        }
        
        
      }

}
LifecycleManager::ServantProxy ad_instproc init {} {

	<p>Provides for registering <a href='/api-doc/proc-view?proc=::xosoap::lifecycle::LifecycleManager::ServantProxy+instproc+delegate'>delegate</a> as filter method with a new instance of <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::ServantProxy'>::xosoap::lifecycle::LifecycleManager::ServantProxy</a>.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005

} { my filter delegate}



####################################################
# 	Pooled Per-request lifecycle handling 
####################################################

::xotcl::Class LifecycleManager::TypedPuddleOfInstances -parameter {type number} -ad_doc {
	
	<p>Implementation of basic pooling / puddling for per-request instances. Upon intialization, the puddle is populated with a modifiable number of servant objects of the same type. The puddle class prescribes facilities to retrieve an idle serant (see <a href='/api-doc/proc-view?proc=::xosoap::lifecycle::LifecycleManager::TypedPuddleOfInstances+instproc+getIdleServant'>getIdleServant</a>) or put back into the puddle servants that accomplished their invocation task (see <a href='/api-doc/proc-view?proc=::xosoap::lifecycle::LifecycleManager::TypedPuddleOfInstances+instproc+putBack'>putBack</a>).</p> 
	
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005
	
	@see <a href='/api-doc/proc-view?proc=::xosoap::lifecycle::PerRequestStrategy+instproc+register'>::xosoap::lifecycle::PerRequestStrategy register</a>

}
LifecycleManager::TypedPuddleOfInstances ad_instproc putBack {servant} {

	<p>Accepts an absolute reference to a servant object that will be reappended to the puddle / list of
	idle servants for upcoming / pending invocation tasks, i.e. at the end of the list.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005
	
	@param servant An absolute reference to the servant object that just finished handling an invocation.

} {

	if {[my exists poolList]} {
		my instvar poolList
		
		# destroy the inner state of the servant object ...
		if {[llength [$servant info vars]] > 0} {
		eval $servant unset [$servant info vars] } 
		# and put it back into the servant list
		lappend poolList $servant
	}

}
LifecycleManager::TypedPuddleOfInstances ad_instproc init {} {

	<p>The initialisation of a pool or puddle involves the instantiation of a pre-defined
	number of servant objects of the type determined by <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::PerRequestStrategy'>ruling per-request strategy</a>.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005

} {
	
	my set poolList [list]
	my instvar poolList
	for {set x 1} {$x<=[my number]} {incr x} {
			set servantName [my autoname servant]
			
   			lappend poolList [eval [my type] [self]::$servantName] }   			
   			
   			my debug "poolList: $poolList"
	}

LifecycleManager::TypedPuddleOfInstances ad_instproc getIdleServant {} {

	<p>When the activation routine of the <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::PerRequestStrategy'>ruling per-request strategy</a> is called, the top most
	element in the list of servant elements is returned as idle servant to serve the invocation request. Consequently, it is removed from the list till invocation is accomplished.</p>
	
	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005
	
	@return A concrete servant object retrieved from the list of servants.
	
	@see <a href='/api-doc/proc-view?proc=::xosoap::lifecycle::PerRequestStrategy+instproc+activate'>::xosoap::lifecycle::PerRequestStrategy activate</a>

} {

		if {[my exists poolList]} {
			
			my instvar poolList
			#my log "pre: $poolList"
			set servantName [lindex $poolList 0]
			set poolList [lrange $poolList 1 end]
			#my log "$poolList + $servantName"
			return $servantName
		
		}

}


####################################################
# 	Lifecycle Manager Registry
####################################################

::xotcl::Class LifecycleManagerRegistry -ad_doc {

	<p>The registry of <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager'>lifecycle managers</a> stores
	tuples of unique object ids and corresponding <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager'>lifecycle managers</a>. At invocation time, the <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::ServantProxy'>servant proxy</a> in charge requests the  <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager'>lifecycle manager</a> by passing the object id to the registry (see <a href='/api-doc/proc-view?proc=::xosoap::lifecycle::LifecycleManager::ServantProxy+instproc+delegate'>delegate</a>).</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005

}
LifecycleManagerRegistry ad_instproc stock {objectID lcManager} {

	<p>Is used by the Invoker to store a new pair of object id and affiliated lifecycle manager during registration of a service.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005
	
	@param objectID The unique object id created by the invoker upon early registration.
	@param lcManager The newly created <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager'>lifecycle manager</a> when a <a href='/xotcl/show-object?object=::xosoap::Service'>service</a> gets registered.	

} {

	my set registry($objectID) $lcManager

}

LifecycleManagerRegistry ad_instproc get {objectID} {

	<p>This method is called by the <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager::ServantProxy'>servant proxy</a> during processing an invocation request in order to get the lifecycle manager identified by the object id.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005
	
	@param objectID The unique object id created by the invoker upon early registration and stored in the service's proxy.
	
	@return An object of type <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager'>::xosoap::lifecycle::LifecycleManager</a> 

} {

	return [my set registry($objectID)]

}

LifecycleManagerRegistry ad_instproc remove {objectID} {

	<p>Can be used to remove a <a href='/xotcl/show-object?object=::xosoap::lifecycle::LifecycleManager'>lifecycle manager</a> from the registry.</p>

	@author stefan.sobernig@wu-wien.ac.at
	@creation-date October, 17 2005
	
	@param objectID The unique object id created by the invoker upon early registration.

} {

	if {[my exists registry]} { 
	
		my instvar registry 
		array unset $registry($objectID)	
	}

}


}


