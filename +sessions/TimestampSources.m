classdef TimestampSources < dj.Relvar
    properties(Constant)
        table = dj.Table('sessions.TimestampSources');
    end
    
    methods 
        function self = TimestampSources(varargin)
            self.restrict(varargin{:})
        end
    end
end
