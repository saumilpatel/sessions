%{
ephys.SpikesAligned (computed) # Settings for computing the PSTH

-> ephys.SpikesAlignedSet
-> ephys.Spikes
---
spikesaligned_ts=CURRENT_TIMESTAMP: timestamp       # automatic timestamp. Do not edit
%}

classdef SpikesAligned < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.SpikesAligned');
    end
    
    methods 
        function self = SpikesAligned(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            % Trigger all the channels of spikes aligned to import
            % JC 2011-10-12
            tuple = key;
            
            insert(this,tuple);
            
            makeTuples(ephys.SpikesAlignedTrial, key);
        end
    end
end
