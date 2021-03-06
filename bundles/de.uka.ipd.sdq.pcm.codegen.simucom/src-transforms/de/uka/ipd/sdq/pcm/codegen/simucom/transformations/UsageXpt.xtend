package de.uka.ipd.sdq.pcm.codegen.simucom.transformations

import com.google.inject.Inject
import org.palladiosimulator.pcm.allocation.Allocation
import org.palladiosimulator.pcm.repository.InfrastructureProvidedRole
import org.palladiosimulator.pcm.repository.InfrastructureRequiredRole
import org.palladiosimulator.pcm.repository.OperationProvidedRole
import org.palladiosimulator.pcm.repository.OperationRequiredRole
import org.palladiosimulator.pcm.system.System
import org.palladiosimulator.pcm.usagemodel.AbstractUserAction
import org.palladiosimulator.pcm.usagemodel.Stop
import org.palladiosimulator.pcm.usagemodel.UsageModel
import org.palladiosimulator.pcm.usagemodel.UsageScenario

abstract class UsageXpt {
	@Inject extension JavaNamesExt
	@Inject extension PCMext
	@Inject extension UserActionsXpt

	//-----------------------------------
	// For a usage model generate for each
	// usage scenario a usage scenario driver
	// and finally (optionally) a main class which can be run
	// standalone
	//-----------------------------------
	def usageModel(UsageModel um, Allocation a) '''
		«FOR scenario : um.usageScenario_UsageModel»«scenario.usageScenarioTM(a)»«ENDFOR»
		«um.mainTM»
	'''

	//----------------------
	// Generic helper methods
	//----------------------
	def dispatch systemMemberVar(OperationProvidedRole opr) '''
		protected «opr.providedInterface__OperationProvidedRole.fqn()» «opr.portMemberVar()» = null;
	'''

	def dispatch systemMemberVar(InfrastructureProvidedRole ipr) '''
		protected «ipr.providedInterface__InfrastructureProvidedRole.fqn()» «ipr.portMemberVar()» = null;
	'''

	def String userActions(AbstractUserAction aua) '''
		«aua.userAction»
		«IF !(aua instanceof Stop)»
			«aua.successor.userActions»
		«ENDIF»
	'''

	def dispatch dummyRequiredSystemTM(OperationRequiredRole orr, System s) '''
		null
	'''

	def dispatch dummyRequiredSystemTM(InfrastructureRequiredRole irr, System s) '''
		null
	'''

	def usageScenarioConstructorContextInit(UsageScenario us, Allocation a) '''
		// Initialise local interface pointer pointing to system roles
		«FOR pr : us.querySystemCalls.map[providedRole_EntryLevelSystemCall].toSet»
			«pr.portMemberVar()» = my«pr.providingEntity_ProvidedRole.javaName()».«pr.portGetterName()»();
		«ENDFOR»
	'''
	
	//------------------------------------
	// Template method to generate a main
	// class which starts the usage scenarios
	// in the usage model. Can be used to 
	// generate runnable test drivers
	//------------------------------------
	def CharSequence mainTM(UsageModel um)

	//------------------------------------
	// Template method to generate a class
	// implementing the usage scenario driver
	//------------------------------------
	def CharSequence usageScenarioTM(UsageScenario us, Allocation a)
}
