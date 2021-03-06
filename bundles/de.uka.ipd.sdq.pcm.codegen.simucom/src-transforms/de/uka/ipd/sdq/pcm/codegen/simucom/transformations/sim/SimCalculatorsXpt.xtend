package de.uka.ipd.sdq.pcm.codegen.simucom.transformations.sim

import com.google.inject.Inject
import de.uka.ipd.sdq.pcm.codegen.simucom.transformations.CalculatorsXpt
import de.uka.ipd.sdq.pcm.codegen.simucom.transformations.JavaNamesExt
import de.uka.ipd.sdq.pcm.codegen.simucom.transformations.PCMext
import de.uka.ipd.sdq.pcm.codegen.simucom.transformations.SensorsExt
import org.palladiosimulator.pcm.repository.BasicComponent
import org.palladiosimulator.pcm.repository.RepositoryComponent
import org.palladiosimulator.pcm.seff.ExternalCallAction
import org.palladiosimulator.pcm.seff.InternalAction
import org.palladiosimulator.pcm.seff.ResourceDemandingSEFF
import org.palladiosimulator.pcm.seff.ServiceEffectSpecification
import org.palladiosimulator.pcm.usagemodel.EntryLevelSystemCall
import org.palladiosimulator.pcm.usagemodel.UsageScenario

class SimCalculatorsXpt extends CalculatorsXpt {
	@Inject extension JavaNamesExt
	@Inject extension PCMext
	@Inject extension SensorsExt

	def dispatch String setupCalculators(UsageScenario us) '''
		if(getModel().getConfiguration().getSimulateFailures()){
			«us.setupCalculatorExecutionResult»
		}
	
		«FOR systemCall : us.querySystemCalls»
			«systemCall.setupCalculators»
		«ENDFOR»
	'''

	def dispatch String setupCalculators(EntryLevelSystemCall call) '''
		«val callName = "Call_"+call.operationSignature__EntryLevelSystemCall.javaSignature()+" <EntryLevelSystemCall id: "+call.id+" >"»
			// Setup calculator for system call «call.entityName» («call.id»)
			«callName.setupCalculatorResponseTime("start"+callName, "end"+callName)»
	'''

	def dispatch String setupCalculators(RepositoryComponent comp) '''
		«IF (comp instanceof BasicComponent) »
			«FOR seff : (comp as BasicComponent).serviceEffectSpecifications__BasicComponent»
				«seff.setupCalculators»
			«ENDFOR»
		«ELSE»
		«ENDIF»  
«««		«REM»TODO: Should there be calculators for RepositoryComponents other than BasicComponent?«ENDREM» 
	'''

	def dispatch String setupCalculators(ServiceEffectSpecification seff) '''
		«/* ERROR "This should never be called!" */»
	'''

	def dispatch String setupCalculators(ResourceDemandingSEFF seff) '''
		// Setup calculators for service call «seff.describedService__SEFF.entityName»,
«««		// contained ExternalCallActions: «seff.steps_Behaviour.findStart().queryExternalCallActions(newArrayList).head.entityName» («seff.steps_Behaviour.findStart().queryExternalCallActions(newArrayList).head.id»)
«««		// TODO: head?
		«FOR callAction : seff.steps_Behaviour.findStart().queryExternalCallActions(newArrayList)»
			«callAction.setupCalculators» 
		«ENDFOR»
«««		«REM»Remove the following two lines in order to disable measurements on infrastructure calls«ENDREM»
«««		// TODO: head?»
«««		// contained InternalActions: «seff.steps_Behaviour.findStart().queryInternalActions(newArrayList).head.entityName» («seff.steps_Behaviour.findStart().queryInternalActions(newArrayList).head.id»)
		«FOR callAction : seff.steps_Behaviour.findStart().queryInternalActions(newArrayList)»
			«callAction.setupCalculators»
		«ENDFOR»
	'''

	def dispatch String setupCalculators(ExternalCallAction action) '''
		// Old: "Call "+this.calledService_ExternalService.interface__OperationSignature.entityName+"."+this.calledService_ExternalService.javaSignature()+" <AssemblyCtx: \"+this.assemblyContext.getId()+\", CallID: "+ this.id +">"
		«val callName = externalCallActionDescription(action.calledService_ExternalService, action)»
			// ExternalCallAction «action.entityName» («action.id»)
			«callName.setupCalculatorResponseTime("start" + callName, "end" + callName)»
			if(getModel().getConfiguration().getSimulateFailures()){
				«action.setupCalculatorExecutionResult(callName)»
			}
	'''
	
	def dispatch String setupCalculators(InternalAction action) '''
		«FOR infrastructureCall : action.infrastructureCall__Action»
			«val callName = internalActionDescription(infrastructureCall.signature__InfrastructureCall, action)»
				// InternalAction «action.entityName» («action.id»)
				«callName.setupCalculatorResponseTime("start" + callName, "end" + callName)»
		«ENDFOR»
	'''
}