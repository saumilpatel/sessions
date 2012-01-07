classdef BehaviorTraces < dj.Relvar
    properties(Constant)
        table = dj.Table('sessions.BehaviorTraces');
    end
    
    methods 
        function self = BehaviorTraces(varargin)
            self.restrict(varargin{:})
        end
    end
end
