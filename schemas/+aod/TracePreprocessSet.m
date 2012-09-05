%{
aod.TracePreprocessSet (imported) # A scan site

->aod.TracePreprocessSetParam
---
%}

classdef TracePreprocessSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('aod.TracePreprocessSet');
        popRel = aod.TracePreprocessSetParam - acq.AodScanIgnore;
    end
    
    methods 
        function self = TracePreprocessSet(varargin)
            self.restrict(varargin{:})
        end

        function t = plot( this )
            assert( count(aod.TracePreprocessSet & this) == 1, 'Only one trace set can be plotted');
            
            time = getTimes(aod.TracePreprocess & this);
            traces = fetchn(aod.TracePreprocess & this, 'trace');
            traces = cat(2,traces{:});
            
            plot(time,bsxfun(@plus,traces*4,1:size(traces,2)))
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
