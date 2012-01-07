%{
ephys.ClusterSetParam (manual) # Detection methods

-> ephys.DetectionSetParam
clustering_method: enum('MultiUnit','Utah')          # The method to use for detection
---
detectionsetparam_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef ClusterSetParam < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.ClusterSetParam');
    end
    
    methods 
        function self = ClusterSetParam(varargin)
            self.restrict(varargin{:})
        end
    end
end
