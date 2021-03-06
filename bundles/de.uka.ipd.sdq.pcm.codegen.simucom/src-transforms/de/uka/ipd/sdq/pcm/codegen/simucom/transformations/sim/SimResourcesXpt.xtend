package de.uka.ipd.sdq.pcm.codegen.simucom.transformations.sim

import com.google.inject.Inject
import org.palladiosimulator.analyzer.completions.NetworkDemandParametricResourceDemand
import de.uka.ipd.sdq.pcm.codegen.simucom.helper.M2TFileSystemAccess
import de.uka.ipd.sdq.pcm.codegen.simucom.transformations.JavaNamesExt
import de.uka.ipd.sdq.pcm.codegen.simucom.transformations.ResourcesXpt
import org.palladiosimulator.pcm.repository.PassiveResource
import org.palladiosimulator.pcm.resourceenvironment.CommunicationLinkResourceSpecification
import org.palladiosimulator.pcm.resourceenvironment.LinkingResource
import org.palladiosimulator.pcm.resourceenvironment.ProcessingResourceSpecification
import org.palladiosimulator.pcm.resourceenvironment.ResourceContainer
import org.palladiosimulator.pcm.resourceenvironment.ResourceEnvironment
import org.palladiosimulator.pcm.seff.seff_performance.ParametricResourceDemand
import org.palladiosimulator.pcm.seff.seff_performance.ResourceCall
import de.uka.ipd.sdq.pcm.transformations.Helper

class SimResourcesXpt extends ResourcesXpt {
	@Inject extension JavaNamesExt
	@Inject extension SimMeasuringPointExt
	
	@Inject M2TFileSystemAccess fsa
	
	// ----------------------------
	// Templates to generate simulated resources and resource environments
	// ----------------------------
	
	// Old: Load the resource demand on a simulated resource
	def dispatch resourceDemand(ParametricResourceDemand prd) '''
	    {
	      double demand = de.uka.ipd.sdq.simucomframework.variables.converter.NumberConverter.toDouble(ctx.evaluate("«prd.specification_ParametericResourceDemand.specification.specificationString()»",Double.class));
	      ctx.findResource(this.completeAssemblyContextID).loadActiveResource(ctx.getThread(),"«prd.requiredResource_ParametricResourceDemand.id»",demand);
	    }
	'''
	
	def dispatch resourceDemand(NetworkDemandParametricResourceDemand ndprd) '''
	    {
	      double demand = de.uka.ipd.sdq.simucomframework.variables.converter.NumberConverter.toDouble(ctx.evaluate("«ndprd.specification_ParametericResourceDemand.specification.specificationString()»",Double.class));
	      ctx.findResource(this.completeAssemblyContextID).loadActiveResource(ctx.getThread(),"«ndprd.requiredCommunicationLinkResource_ParametricResourceDemand.id»",demand);
	    }
	'''
	
	// New: Load resource demand using ResourceInterfaces and additional parameters
	def dispatch resourceDemand(ResourceCall rc) '''
 {
            
      java.util.HashMap<String, java.io.Serializable> parameterMap = new java.util.HashMap<>();
      String typeString;
      String specificationString;
      java.io.Serializable solvedSpecification;
      
   	 			
   	 	«FOR parm: rc.signature__ResourceCall.parameter__ResourceSignature»
   	 	 	«FOR spec: rc.inputVariableUsages__CallAction»	
   	 	 	if("«spec.namedReference__VariableUsage.referenceName.javaString()»".equals("«parm.parameterName.javaString()»")){       
   	 	 	
   	 	 	//remove Brackets [] from specification String	
   	 	 	specificationString = (String)"«rc.numberOfCalls__ResourceCall.variableCharacterisation_Specification.specification_VariableCharacterisation.specification.specificationString()»".subSequence(1, "«rc.numberOfCalls__ResourceCall.variableCharacterisation_Specification.specification_VariableCharacterisation.specification.specificationString()»".length() - 1);
   	 	 	typeString = "«parm.dataType__Parameter.toString()»";
   	 	 	
   	 	 	solvedSpecification = null;     		
   	 	 	
   	 	 	if(typeString.contains("INT")){          			
   	 	 	solvedSpecification = ctx.evaluate(specificationString,Integer.class);
   	 	 	}else if(typeString.contains("STRING")){                			
   	 	 	solvedSpecification = ctx.evaluate(specificationString,String.class);
   	 	 	} else if(typeString.contains("BOOL")){      			
   	 	 	solvedSpecification = ctx.evaluate(specificationString,Boolean.class);
   	 	 	} else if(typeString.contains("DOUBLE")){        			
   	 	 	solvedSpecification = ctx.evaluate(specificationString,Double.class);
   	 	 	} else if(typeString.contains("CHAR")){        			
   	 	 	solvedSpecification = ctx.evaluate(specificationString,Character.class);
   	 	 	} else if(typeString.contains("BYTE")){		
   	 	 	solvedSpecification = ctx.evaluate(specificationString,Byte.class);
   	 	 	} else if(typeString.contains("LONG")){                  			
   	 	 	solvedSpecification = ctx.evaluate(specificationString,Long.class);
   	 	 	} else {
   	 	 	throw new RuntimeException("Just Primitive Data Types are supported.");
   	 	 	}
   	 	 	
   	 	 	parameterMap.put("«spec.namedReference__VariableUsage.referenceName.javaString()»", solvedSpecification);            
   	 	 	}  	  	
   	 	 	
    	«ENDFOR»	     
   	 «ENDFOR»
   	 	
      double demand = de.uka.ipd.sdq.simucomframework.variables.converter.NumberConverter.toDouble(ctx.evaluate("«rc.numberOfCalls__ResourceCall.specification.specificationString()»",Double.class));
      if(parameterMap.size()>=1){
      	ctx.findResource(this.assemblyContext.getId()).loadActiveResource(ctx.getThread(),"«rc.resourceRequiredRole__ResourceCall.requiredResourceInterface__ResourceRequiredRole.entityName.javaString()»",«rc.signature__ResourceCall.resourceServiceId», parameterMap, demand);     	
      }else{
      	ctx.findResource(this.assemblyContext.getId()).loadActiveResource(ctx.getThread(),"«rc.resourceRequiredRole__ResourceCall.requiredResourceInterface__ResourceRequiredRole.entityName.javaString()»",«rc.signature__ResourceCall.resourceServiceId»,demand);     	
      }
     
   } 
	'''
	
	// ----------------------------
	// Templates for a simulated resource environment
	// Generate a class which contains the model information
	// and sets up simulated resources accordingly
	// ----------------------------
	def resourceEnvironmentRoot(ResourceEnvironment re) {
		val fileName = "main/ResourceEnvironment.java"
		val fileContent = '''package main;
			
			public class ResourceEnvironment implements de.uka.ipd.sdq.simucomframework.resources.IResourceContainerFactory {
				
				private static final ResourceEnvironment instance = new ResourceEnvironment();
				
				public static ResourceEnvironment getInstance() {
					return instance;
				}
			
			   «re.resourceContainerInit»
			}
		'''
		
				
		fsa.generateFile(fileName, fileContent)
	}
	
	def resourceContainerInit(ResourceEnvironment re) '''
		public String[] getResourceContainerIDList() {
			java.util.List<String> resourceContainerIds = new java.util.ArrayList<String>();
			«FOR rc : re.resourceContainer_ResourceEnvironment»«rc.resourceContainerAdd»«ENDFOR»
			return resourceContainerIds.toArray(new String[]{});
		}
	
		public String[] getLinkingResourceContainerIDList() {
			return new String[] { 
				«FOR rc : re.linkingResources__ResourceEnvironment SEPARATOR ","»
					"«rc.id»"
				«ENDFOR»
			};
		}
		
		public java.util.ArrayList<String> getFromResourceContainerID(String linkingResourceContainerID) {
			java.util.ArrayList<String> resultList = new java.util.ArrayList<String>();
			«FOR rc : re.linkingResources__ResourceEnvironment»
				if(linkingResourceContainerID.equals("«rc.id»")) {
				«FOR id : rc.connectedResourceContainers_LinkingResource.map[id]»
					resultList.add("«id»");
				«ENDFOR»
				}
			«ENDFOR»
			return resultList;
		}
		
		public java.util.ArrayList<String> getToResourceContainerID(String linkingResourceContainerID) {
			java.util.ArrayList<String> resultList = new java.util.ArrayList<String>();
			«FOR rc : re.linkingResources__ResourceEnvironment»
				if (linkingResourceContainerID.equals("«rc.id»")) {
				«FOR id : rc.connectedResourceContainers_LinkingResource.map[id]»
					resultList.add("«id»");
				«ENDFOR»
				}
			«ENDFOR»
			return resultList;
		}
		
		public String getLinkingResourceContainerID(String fromResourceContainerID, String toResourceContainerID) {
			for (String id: getLinkingResourceContainerIDList()) {
				if (getFromResourceContainerID(id).contains(fromResourceContainerID) && getToResourceContainerID(id).contains(toResourceContainerID)) {
					return id;
				}
			}
			return null;
		}
		
		public void fillResourceContainerWithResources(de.uka.ipd.sdq.simucomframework.resources.SimulatedResourceContainer rc) {
			«FOR rc : re.resourceContainer_ResourceEnvironment»«rc.resourceContainerCaseResources»«ENDFOR»
				throw new RuntimeException("Unknown resource container should be initialised. This should never happen");	
		}
		
		public void fillResourceContainerWithNestedResourceContainers(de.uka.ipd.sdq.simucomframework.resources.SimulatedResourceContainer rc) {
			«FOR rc : re.resourceContainer_ResourceEnvironment»«rc.resourceContainerCaseResourceContainers»«ENDFOR»
				throw new RuntimeException("Unknown resource container should be initialised. This should never happen");	
		}
	
		public void fillLinkingResourceContainer(de.uka.ipd.sdq.simucomframework.resources.SimulatedLinkingResourceContainer rc) {
			«FOR lr : re.linkingResources__ResourceEnvironment SEPARATOR " else "»«lr.linkingResourceCase»«ENDFOR»
			«IF re.linkingResources__ResourceEnvironment.size > 0»
			else
				throw new RuntimeException("Unknown resource container should be initialised. This should never happen");
			«ENDIF»	
		}
	
	'''
	
	def String resourceContainerAdd(ResourceContainer rc) '''
		resourceContainerIds.add("«rc.id»");
		«FOR nrc : rc.nestedResourceContainers__ResourceContainer»«nrc.resourceContainerAdd»«ENDFOR»
	'''
	
	def String resourceContainerCaseResources(ResourceContainer rc) '''
		if (rc.getResourceContainerID().equals("«rc.id»")) {
			«FOR ars : rc.activeResourceSpecifications_ResourceContainer»«ars.activeResourceAdd»«ENDFOR»
«««			«REM» Refactor!
«««			«EXPAND PassiveResourceAdd FOREACH this.passiveResourceSpecifications_ResourceContainer»
«««			«ENDREM»
		} else 
		«FOR nrc : rc.nestedResourceContainers__ResourceContainer»«nrc.resourceContainerCaseResources»«ENDFOR»
	'''
	
	def String resourceContainerCaseResourceContainers(ResourceContainer rc) '''
		if (rc.getResourceContainerID().equals("«rc.id»")) {
			«FOR nrc : rc.nestedResourceContainers__ResourceContainer»«nrc.nestedResourceContainerAdd»«ENDFOR»
			«IF rc.parentResourceContainer__ResourceContainer != null»
			«rc.parentResourceContainer__ResourceContainer.parentResourceContainerAdd»
			«ENDIF»
		} else 
		«FOR nrc : rc.nestedResourceContainers__ResourceContainer»«nrc.resourceContainerCaseResourceContainers»«ENDFOR»
	'''
	
	def linkingResourceCase(LinkingResource lr) '''
		if (rc.getResourceContainerID().equals("«lr.id»")) {
			«lr.communicationLinkResourceSpecifications_LinkingResource.linkingResourceAdd»
		}
	'''
	
	def linkingResourceAdd(CommunicationLinkResourceSpecification clrs) '''
		rc.addActiveResource(
		     (org.palladiosimulator.pcm.resourceenvironment.LinkingResource) org.palladiosimulator.commons.emfutils.EMFLoadHelper.loadAndResolveEObject("«clrs.linkingResource_CommunicationLinkResourceSpecification.getResourceURI()»"),
		rc.getResourceContainerID());
	'''
	
	def nestedResourceContainerAdd(ResourceContainer rc) '''
		rc.addNestedResourceContainer("«rc.id»");
	'''
	
	def parentResourceContainerAdd(ResourceContainer rc) '''
		rc.setParentResourceContainer("«rc.id»");
	'''
	
	def activeResourceAdd(ProcessingResourceSpecification prs) '''
		String[] «prs.activeResourceType_ActiveResourceSpecification.id.javaVariableName()»_provInterfaces = null;
		«IF prs.activeResourceType_ActiveResourceSpecification.resourceProvidedRoles__ResourceInterfaceProvidingEntity.isEmpty»
		«ELSE»
			«prs.activeResourceType_ActiveResourceSpecification.id.javaVariableName()»_provInterfaces = new String[«prs.activeResourceType_ActiveResourceSpecification.resourceProvidedRoles__ResourceInterfaceProvidingEntity.size»];
			
			«var counter0 = 0»
			«FOR resProvRole : prs.activeResourceType_ActiveResourceSpecification.resourceProvidedRoles__ResourceInterfaceProvidingEntity»
				«prs.activeResourceType_ActiveResourceSpecification.id.javaVariableName()»_provInterfaces[«counter0»] = "«resProvRole.providedResourceInterface__ResourceProvidedRole.entityName.javaString()»";
				«Helper::toEmptyString(counter0 = counter0 + 1)»
			«ENDFOR»
		«ENDIF»
		rc.addActiveResource(
		(org.palladiosimulator.pcm.resourceenvironment.ProcessingResourceSpecification) org.palladiosimulator.commons.emfutils.EMFLoadHelper.loadAndResolveEObject("«prs.getResourceURI()»"),
		«prs.activeResourceType_ActiveResourceSpecification.id.javaVariableName()»_provInterfaces,
		rc.getResourceContainerID(),
			«prs.schedulingStrategy(prs.eContainer as ResourceContainer)»
			);
	'''
	
	def schedulingStrategy(ProcessingResourceSpecification prs, ResourceContainer container) '''
		«IF (prs.schedulingPolicy.id.equals("FCFS")) || (prs.schedulingPolicy.id.equals("ProcessorSharing")) || (prs.schedulingPolicy.id.equals("Delay"))»
			«IF prs.schedulingPolicy.id.equals("FCFS")»
				de.uka.ipd.sdq.simucomframework.resources.SchedulingStrategy.FCFS
			«ENDIF»
			«IF prs.schedulingPolicy.id.equals("ProcessorSharing")»
				de.uka.ipd.sdq.simucomframework.resources.SchedulingStrategy.PROCESSOR_SHARING
			«ENDIF»
			«IF prs.schedulingPolicy.id.equals("Delay")»
				de.uka.ipd.sdq.simucomframework.resources.SchedulingStrategy.DELAY
			«ENDIF»
		«ELSE»
			"«prs.schedulingPolicy.id»"
		«ENDIF»
	'''
	
//	«REM»TODO: Refactor
//	def dispatch PassiveResourceAdd(PassiveResourceSpecification xyz) '''
//		rc.addPassiveResource(
//			"«xyz.passiveResourceType_PassiveResourceSpecification.entityName»",
//			«xyz.capacity»);
//	'''
//	«ENDREM»

	// overwritten template methods
	
	override resourceDemandTM(ParametricResourceDemand rc) {
		resourceDemand(rc)
	}
	
	override resourceDemandTM(ResourceCall rc) {
		resourceDemand(rc)
	}
	
	//This method wasn't implemented in the original script
	override passiveResourceInitTM(PassiveResource pr) '''
	'''
	
}