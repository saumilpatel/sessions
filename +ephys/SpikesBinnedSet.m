%{
ephys.SpikesBinnedSet (computed) # Set of spikes binned a certain way

-> stimulation.StimTrialGroup
-> ephys.SpikesBinnedConditions
-> ephys.SpikeSet
---
spikesbinnedset_ts=CURRENT_TIMESTAMP: timestamp             # automatic timestamp. Do not edit
%}

classdef SpikesBinnedSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ephys.SpikesBinnedSet');
        popRel = ephys.SpikeSet*stimulation.StimTrialGroup*ephys.SpikesBinnedConditions
    end
    
    methods 
        function self = SpikesBinnedSet(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            tuple = key;
            
            insert(this,tuple);
            
            % Insert a StimTrialGroupBinned for each neuron
            tuples = dj.utils.structJoin(key,fetch(ephys.Spikes(key)));
            for tuple = tuples'
                disp(sprintf('Binning spikes for spike id %d',tuple.spike_id));
                makeTuples(ephys.StimTrialGroupBinned, tuple);
            end
        end
    end
end
