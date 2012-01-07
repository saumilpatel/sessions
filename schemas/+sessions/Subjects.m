classdef Subjects < dj.Relvar
    properties(Constant)
        table = dj.Table('sessions.Subjects');
    end
    
    methods 
        function self = Subjects(varargin)
            self.restrict(varargin{:})
        end
    end
end
