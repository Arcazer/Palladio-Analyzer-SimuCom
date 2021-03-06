package de.uka.ipd.sdq.pcm.transformations.builder.seff;

import java.util.ArrayList;
import java.util.Collection;

import org.palladiosimulator.pcm.parameter.VariableUsage;
import org.palladiosimulator.pcm.seff.AbstractAction;
import org.palladiosimulator.pcm.seff.SeffFactory;
import org.palladiosimulator.pcm.seff.SetVariableAction;

public class SetVariableActionDescriptor extends AbstractActionDescriptor {
    private Collection<VariableUsage> vus;

    public SetVariableActionDescriptor(Collection<VariableUsage> vus) {
        super();
        this.vus = vus;
    }

    public SetVariableActionDescriptor(VariableUsage vu) {
        vus = new ArrayList<VariableUsage>();
        vus.add(vu);
    }

    @Override
    public AbstractAction createAction() {
        SetVariableAction action = SeffFactory.eINSTANCE.createSetVariableAction();
        action.setEntityName("ResultSetter");
        action.getLocalVariableUsages_SetVariableAction().addAll(this.getVariableUsages());
        return action;
    }

    protected Collection<? extends VariableUsage> getVariableUsages() {
        return this.vus;
    }
}
