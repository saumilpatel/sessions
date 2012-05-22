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
            
            makeTuples( this, key )
        end
    end
end
