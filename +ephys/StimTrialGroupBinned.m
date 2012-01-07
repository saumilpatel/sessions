%{
ephys.StimTrialGroupBinned (computed) # Settings for computing the PSTH

-> ephys.SpikesBinnedSet
-> ephys.Spikes
---
stimtrialgroupbinned_ts=CURRENT_TIMESTAMP: timestamp        # automatic timestamp. Do not edit
%}

classdef StimTrialGroupBinned < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.StimTrialGroupBinned');
    end
    
    methods 
        function self = StimTrialGroupBinned(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            % Trigger all the channels of spikes binned to import
            % JC 2011-10-12
            tuple = key;
            
            insert(this,tuple);
            
            makeTuples(ephys.SpikesBinned, key);
        end
    end
end
