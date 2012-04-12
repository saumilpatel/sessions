%{
acq.EphysStimulationLink (computed)   # stimulation sessions that were recorded

->acq.Ephys
->acq.Stimulation
->acq.SessionsCleanup
---
%}

classdef EphysStimulationLink < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('acq.EphysStimulationLink');
        popRel = acq.Ephys * acq.Stimulation ...
            & acq.SessionsCleanup ...
            & 'ephys_start_time <= stim_start_time AND ephys_stop_time >= stim_stop_time';
    end
    
    methods
        function self = EphysStimulationLink(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            insert(self, key);
        end
    end
end
