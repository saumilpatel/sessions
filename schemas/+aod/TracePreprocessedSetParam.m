%{
aod.TracePreprocessedSetParam (manual) # A preprocessing method

->aod.TraceSet
->aod.TracePreprocessedSetMethod
---
%}

classdef TracePreprocessedSetParam < dj.Relvar
    properties(Constant)
        table = dj.Table('aod.TracePreprocessedSetParam');
    end
    
    methods 
        function self = TracePreprocessedSetParam(varargin)
            self.restrict(varargin{:})
        end
    end
end
