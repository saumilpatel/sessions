%{
ephys.ClusterSet (computed) # Detection methods

-> ephys.ClusterSetParam
---
clusterset_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef ClusterSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ephys.ClusterSet');
        popRel = ephys.ClusterSetParam;
    end
    
    methods 
        function self = ClusterSet(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(this, key)
            if strcmp(fetch1(ephys.ClusterSetParam(key), 'clustering_method'), 'MultiUnit')
                insert(this, key);
            elseif strcmp(fetch1(ephys.ClusterSetParam(key), 'clustering_method'), 'Utah')
                tuple = key;

                insert(this,tuple);
            
                makeTuples(clustering.VariationalClustering, key);
            else
                error('Unimplemented cluster set type');
            end
        end
    end
end
