%{
ephys.SpikesAlignedSet (computed) # Set of spikes binned a certain way

-> stimulation.StimTrialGroup
-> ephys.SpikesAlignedConditions
-> ephys.SpikeSet
---
spikesalignedset_ts=CURRENT_TIMESTAMP: timestamp             # automatic timestamp. Do not edit
%}

classdef SpikesAlignedSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ephys.SpikesAlignedSet');
        popRel = (ephys.SpikeSet .* ephys.Spikes) *stimulation.StimTrialGroup*ephys.SpikesAlignedConditions
    end
    
    methods 
        function self = SpikesAlignedSet(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            tuple = key;
            
            insert(this,tuple);
            
            % Insert a StimTrialGroupBinned for each neuron
            tuples = dj.utils.structJoin(key,fetch(ephys.Spikes(key)));
            for tuple = tuples'
                disp(sprintf('Importing aligned spikes for spike id %d',tuple.spike_id));
                makeTuples(ephys.StimTrialGroupAligned, tuple);
            end
        end
    end
end
