%{
sort.TetrodesMoGFinalize (imported) # finalize clustering

->sort.TetrodesMoGManual
---
final_sort_file                      : varchar(255) # name of file
finalize_sort_ts = CURRENT_TIMESTAMP : timestamp    # current timestamps
%}

classdef TetrodesMoGFinalize < dj.Relvar
    properties(Constant)
        table = dj.Table('sort.TetrodesMoGFinalize');
    end
    
    methods 
        function self = TetrodesMoGFinalize(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            % do model refit
            error('TODO')
            
            % insert(self, key);
            
            % insert single units into TetrodesMoGUnits
        end
    end
end
