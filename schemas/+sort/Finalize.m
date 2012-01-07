%{
sort.Finalize (imported) # finalize clustering

->sort.Manual
---
finalize_sort_ts = CURRENT_TIMESTAMP : timestamp  # current timestamps
%}

classdef Finalize < dj.Relvar
    properties(Constant)
        table = dj.Table('sort.Finalize');
    end
    
    methods 
        function self = Finalize(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            % do model refit
            % TODO
            
            insert(self, key);
        end
    end
end
