%{
aod.TracePreprocessed (imported) # A scan site

->aod.TracePreprocessedSetParam
->aod.Traces
---
trace           : longblob          # The unfiltered trace
t0              : double            # The starting time
fs              : double            # Sampling rate
%}

classdef TracePreprocessed < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('aod.TracePreprocessed');
        popRel = aod.TracePreprocessed;
    end
    
    methods 
        function self = TracePreprocessed(varargin)
            self.restrict(varargin{:})
        end
    
        function makeTuples( this, key )
            % Import a spike set
            
            ids = fetchn(aod.Traces(key),'cell_num');
            
            for i = 1:length(ids)
                tuple = key;
                tuple.cell_num = ids(i);
                
                aodTrace = fetch(aod.Trace(tuple),'*');
                
                switch (tuple.preprocessed_method_num)
                end
            
                insert(this,tuple);
            end
        end
    end
end
