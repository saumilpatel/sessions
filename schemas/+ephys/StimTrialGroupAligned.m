%{
ephys.StimTrialGroupAligned (computed) # Settings for computing the PSTH

-> ephys.SpikesAlignedSet
-> ephys.Spikes
---
stimtrialgroupaligned_ts=CURRENT_TIMESTAMP: timestamp       # automatic timestamp. Do not edit
%}

classdef StimTrialGroupAligned < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.StimTrialGroupAligned');
    end
    
    methods 
        function self = StimTrialGroupAligned(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            % Trigger all the channels of spikes aligned to import
            % JC 2011-10-12
            tuple = key;
            
            insert(this,tuple);
            
            makeTuples(ephys.SpikesAligned, key);
        end
    end
end
