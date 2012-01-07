%{
ephys.EphysStimLink (manual) # Link stim to ephys

-> sessions.Ephys
-> sessions.Stimulation
---
ephyssetstimlink_ts=CURRENT_TIMESTAMP: timestamp            # automatic timestamp. Do not edit
%}

classdef EphysStimLink < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.EphysStimLink');
    end
    
    methods 
        function self = EphysSetStimLink(varargin)
            self.restrict(varargin{:})
        end
    end
end
