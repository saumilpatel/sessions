classdef Ephys < dj.Relvar
    properties(Constant)
        table = dj.Table('sessions.Ephys');
    end
    
    methods 
        function self = Ephys(varargin)
            self.restrict(varargin{:})
        end
    end
end
