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
    
    methods (Static)
        function createSets(key ,method)
            assert(count(aod.TraceSet & key) > 0, 'No sets to attach to found');
            preprocess_method_num = fetch1(aod.TracePreprocessedSetMethod & ...
                ['preprocessed_method_name="' method '"'], 'preprocessed_method_num');
            ts = fetch(aod.TraceSet & key);
            for i = 1:length(ts)
                tuple = ts(i);
                tuple.preprocessed_method_num = preprocess_method_num;
                inserti(aod.TracePreprocessedSetParam, tuple);
            end
        end
    end
end
