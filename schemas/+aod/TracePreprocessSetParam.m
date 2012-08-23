%{
aod.TracePreprocessSetParam (manual) # A preprocessing method

->aod.TraceSet
->aod.TracePreprocessMethod
---
%}

classdef TracePreprocessSetParam < dj.Relvar
    properties(Constant)
        table = dj.Table('aod.TracePreprocessSetParam');
    end
    
    methods 
        function self = TracePreprocessedSetParam(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Static)
        function createSets(key ,method)
            assert(count(aod.TraceSet & key) > 0, 'No sets to attach to found');
            preprocess_method_num = fetch1(aod.TracePreprocessMethod & ...
                ['preprocess_method_name="' method '"'], 'preprocess_method_num');
            ts = fetch(aod.TraceSet & key);
            for i = 1:length(ts)
                tuple = ts(i);
                tuple.preprocess_method_num = preprocess_method_num;
                inserti(aod.TracePreprocessSetParam, tuple);
            end
        end
    end
end
