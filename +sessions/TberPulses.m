classdef TberPulses < dj.Relvar
    properties(Constant)
        table = dj.Table('sessions.TberPulses');
    end
    
    methods 
        function self = TberPulses(varargin)
            self.restrict(varargin{:})
        end
    end
end
