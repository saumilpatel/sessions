%{
aod.TracePreprocessMethod (lookup) # A preprocessing method

preprocess_method_num  : int unsigned   # Preprocessing method
---
preprocess_method_name : varchar(255)   # path to the stimulation data
%}

classdef TracePreprocessMethod < dj.Relvar
    properties(Constant)
        table = dj.Table('aod.TracePreprocessMethod');
    end
    
    methods 
        function self = TracePreprocessMethod(varargin)
            self.restrict(varargin{:})
        end
    end
end
