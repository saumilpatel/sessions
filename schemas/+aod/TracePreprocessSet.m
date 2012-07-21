%{
aod.TracePreprocessSet (imported) # A scan site

->aod.TracePreprocessSetParam
---
%}

classdef TracePreprocessSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('aod.TracePreprocessSet');
        popRel = aod.TracePreprocessSetParam;
    end
    
    methods 
        function self = TracePreprocessSet(varargin)
            self.restrict(varargin{:})
        end

        function t = plot( this )
            assert( count(aod.TracePreprocessSet & this) == 1, 'Only one trace set can be plotted');
            
            t = fetch(aod.TracePreprocess & this, '*');
            t(1) = [];
            traces = cat(2,t.trace);
            traces(1,:) = [];
            time = (1:size(traces,1)) / t(1).fs;
            plot(time,bsxfun(@plus,traces,1:size(traces,2)))
        end        
    end
    
    methods (Access=protected)
        function makeTuples( this, key )
            % Import a spike set
            tuple = key;
                       
            insert(this,tuple);           
            
            makeTuples( aod.TracePreprocess, key )
        end
    end
end
