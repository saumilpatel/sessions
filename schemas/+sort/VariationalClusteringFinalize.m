%{
sort.VariationalClusteringFinalize (computed) # Detection methods

-> sort.VariationalClusteringAutomatic
---
model: LONGBLOB # The fitted model
variationalclusteringfinalize_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef VariationalClusteringFinalize < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('clustering.VariationalClustering');
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
            
            insert(sort.VariationalClusteringAutomatic, key);
            makeTuples(sort.VariationalClusteringSU, key);
        end
    end
end
