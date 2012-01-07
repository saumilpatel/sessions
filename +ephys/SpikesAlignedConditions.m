%{
ephys.SpikesAlignedConditions (lookup) # Settings for trial aligned spikes

event_type      : enum('showStimulus')  # Type of stimulation event
pre_stim_time   : int unsigned          # Time to bin before alignment event
post_stim_time  : int unsigned          # Time after bin before alignment event
---
%}

classdef SpikesAlignedConditions < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.SpikesAlignedConditions');
    end
    
    methods 
        function self = SpikesAlignedConditions(varargin)
            self.restrict(varargin{:})
        end
    end
end
