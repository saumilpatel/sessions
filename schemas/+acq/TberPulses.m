%{
acq.TberPulses (manual)       # trial sync pulses

->acq.Stimulation
tber_pulse_time : bigint # pulse time
---
%}

classdef TberPulses < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.TberPulses');
    end
    
    methods 
        function self = TberPulses(varargin)
            self.restrict(varargin{:})
        end
    end
end
