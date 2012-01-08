
%{
sort.VariationalClusteringLink (computed) # Links ephys.Spikes to cluster

-> sort.VariationalClusteringSU
-> ephys.Spikes
---
variationalclusteringlink_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef VariationalClusteringLink < dj.Relvar
    properties(Constant)
        table = dj.Table('sort.VariationalClusteringLink');
    end
    
    methods
        function self = VariationalClusteringLink(varargin)
            self.restrict(varargin{:})
        end
        
        % makeTuple not implemented.  Inserted by sort.Spikes.makeTuples

    end
end
