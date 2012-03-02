%{
acq.AodStimulationSyncDiode (computed)   # synchronization to photodiode

->acq.StimulationSync
->acq.AodStimulationLink
---
%}

classdef AodStimulationSyncDiode < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.AodStimulationSyncDiode');
    end
    
    methods
        function self = AodStimulationSyncDiode(varargin)
            self.restrict(varargin{:})
        end
    end
end
