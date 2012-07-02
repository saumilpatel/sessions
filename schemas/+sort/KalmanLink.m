%{
sort.KalmanLink (computed) # Links ephys.Spikes to cluster

-> sort.KalmanFinalize
-> ephys.Spikes
---
%}

classdef KalmanLink < dj.Relvar
    properties(Constant)
        table = dj.Table('sort.KalmanLink');
    end
    
    methods
        function self = KalmanLink(varargin)
            self.restrict(varargin{:})
        end
    end
end
