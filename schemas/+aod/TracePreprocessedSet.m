%{
aod.TracePreprocessedSet (imported) # A scan site

->aod.TracePreprocessedSetParam
---
%}

classdef TracePreprocessedSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('aod.TracePreprocessedSet');
        popRel = aod.TracePreprocessedSetParam;
    end
    
    methods 
        function self = TracePreprocessedSet(varargin)
            self.restrict(varargin{:})
        end
    
        function makeTuples( this, key )
            % Import a spike set
            tuple = key;
                       
            insert(this,tuple);           
            
            makeTuples( aod.TracePreprocessed, key )
        end
        
        function t = plot( this )
            assert( count(aod.TracePreprocessedSet & this) == 1, 'Only one trace set can be plotted');
            
            t = fetch(aod.TracePreprocessed & this, '*');
            t(1) = [];
            traces = cat(2,t.trace);
            traces(1,:) = [];
            time = (1:size(traces,1)) / t(1).fs;
            plot(time,bsxfun(@plus,traces,1:size(traces,2)))
        end
    end
end
