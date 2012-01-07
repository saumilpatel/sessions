classdef SessionTimestamps < dj.Relvar
    properties(Constant)
        table = dj.Table('sessions.SessionTimestamps');
    end
    
    methods 
        function self = SessionTimestamps(varargin)
            self.restrict(varargin{:})
        end
    end
end
