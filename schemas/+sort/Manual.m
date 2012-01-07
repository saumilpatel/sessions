%{
sort.Manual (manual) # manual clustering step

->sort.Automatic
---
manual_sort_comment = '' : varchar(255) # optional comment about manual step
manual_sort_ts = CURRENT_TIMESTAMP : timestamp  # current timestamps
%}

classdef Manual < dj.Relvar
    properties(Constant)
        table = dj.Table('sort.Manual');
    end
    
    methods 
        function self = Manual(varargin)
            self.restrict(varargin{:})
        end
    end
end
