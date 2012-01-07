%{
sort.TetrodesMoGManual (manual) # manual clustering step

->sort.TetrodesMoGAutomatic
---
manual_sort_comment = '' : varchar(255) # optional comment about manual step
manual_sort_ts = CURRENT_TIMESTAMP : timestamp  # current timestamps
%}

classdef TetrodesMoGManual < dj.Relvar
    properties(Constant)
        table = dj.Table('sort.TetrodesMoGManual');
    end
    
    methods 
        function self = TetrodesMoGManual(varargin)
            self.restrict(varargin{:})
        end
    end
end
