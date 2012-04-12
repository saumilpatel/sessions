%{
sort.VariationalClusteringFinalize (computed) # Detection methods

-> sort.VariationalClusteringAutomatic
---
variationalclusteringfinalize_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef VariationalClusteringFinalize < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('sort.VariationalClusteringFinalize');
        popRel = sort.VariationalClusteringAutomatic
    end
    
    methods
        function self = VariationalClusteringFinalize(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            % Perform the post processing step
            %
            % JC 2012-02-08
            
            insert(sort.VariationalClusteringFinalize, key);
            makeTuples(sort.VariationalClusteringSU, key);
        end
    end
end
