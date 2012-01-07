%{
ephys.SpikeSet (imported) # Detection methods

-> ephys.ClusterSet
---
spikeset_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef SpikeSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ephys.SpikeSet');
        popRel = ephys.ClusterSet;
    end
    
    methods 
        function self = SpikeSet(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            % Import a spike set
            tuple = key;
            
            insert(this,tuple);
            type = fetch1(ephys.ClusterSet(key), 'clustering_method');
            
            if(strcmp(type,'Utah') == 1)
                makeTuplesUtah(ephys.Spikes, key);
            elseif strcmp(type,'Nonchronic Tetrode')
                makeTuplesTetrode(ephys.Spikes, key);
            elseif strcmp(type,'MultiUnit')
                makeTuplesMultiUnit(ephys.Spikes, key);
            else
                error(sprintf('Unsupported ephys type %s',ephys_type));
            end
        end
    end
end
