%{
ephys.SpikesBinnedConditions (lookup) # Settings for computing the PSTH

bin_width       : int unsigned          # Width of the PSTH bins (ms)
event_type      : enum('showStimulus')  # Type of stimulation event
pre_stim_time   : int unsigned          # Time to bin before alignment event
post_stim_time  : int unsigned          # Time after bin before alignment event
---
%}

classdef SpikesBinnedConditions < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.SpikesBinnedConditions');
    end
    
    methods 
        function self = SpikesBinnedConditions(varargin)
            self.restrict(varargin{:})
        end
    end
end
