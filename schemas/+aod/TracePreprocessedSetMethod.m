%{
aod.TracePreprocessedSetMethod (lookup) # A preprocessing method

preprocessed_method_num  : int unsigned   # Preprocessing method
---
preprocessed_method_name : varchar(255)   # path to the stimulation data
%}

classdef TracePreprocessedSetMethod < dj.Relvar
    properties(Constant)
        table = dj.Table('aod.TracePreprocessedSetMethod');
    end
    
    methods 
        function self = TracePreprocessedSetMethod(varargin)
            self.restrict(varargin{:})
        end
    end
end
