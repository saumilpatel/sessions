classdef Sessions < dj.Relvar
    properties(Constant)
        table = dj.Table('sessions.Sessions');
    end
    
    methods 
        function self = Sessions(varargin)
            self.restrict(varargin{:})
        end
    end
end
