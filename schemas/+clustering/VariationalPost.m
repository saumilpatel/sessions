%{
clustering.VariationalPost (computed) # Detection methods

-> ephys.ClusterSet
---
single_units: int unsigned     # The number of single units
variationalpost_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef VariationalPost < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('clustering.VariationalPost');
        popRel = ephys.ClusterSet('clustering_method="Utah"');
    end
    
    methods 
        function self = VariationalPost(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            % Post process variational clustering
            %
            % JC 2011-11-18
            
            tuple = key;
            
            % Get the children but don't insert yet so we can get the count
            children = makeTuples(clustering.VariationalSU, key);
            tuple.single_units = length(children);
            insert(clustering.VariationalPost, tuple);
          
            % Insert the children
            if ~isempty(children)
                insert(clustering.VariationalSU, children);
            end
        end
    end
end
