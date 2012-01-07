%{
sort.ClusterInfo (imported) # Information on clusters (isolation etc.)

->sort.Finalize
unit_num      : tinyint unsigned  # cluster number on this electrode
---
is_mua        : boolean           # true if cluster is multi unit
iso_false_pos : float             # estimated fraction of false positives
iso_false_neg : float             # estimated fraction of false negatives
iso_total     : float             # estimated fraction of total false assignments
num_spikes    : int unsigned      # total number of spikes
%}

classdef ClusterInfo < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('sort.ClusterInfo');
        popRel = sort.Finalize;
    end
    
    methods
        function self = ClusterInfo(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            
            % for testing only: insert mua + 2 sua clusters
            for i = 1:3
                tuple = key;
                tuple.cluster_num = i;
                tuple.is_mua = (i == 1);
                tuple.iso_false_pos = i * 0.03;
                tuple.iso_false_neg = 0.05 + i * 0.01;
                tuple.iso_total = tuple.iso_false_pos + tuple.iso_false_neg;
                tuple.num_spikes = (4 - i)^2 * 10000;
                self.insert(tuple);
            end
        end
    end
end
