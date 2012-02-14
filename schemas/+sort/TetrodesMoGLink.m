%{
sort.TetrodesMoGLink (computed) # Links ephys.Spikes to cluster

-> sort.TetrodesMoGUnits
-> ephys.Spikes
---
%}

classdef TetrodesMoGLink < dj.Relvar
    properties(Constant)
        table = dj.Table('sort.TetrodesMoGLink');
    end
    
    methods
        function self = TetrodesMoGLink(varargin)
            self.restrict(varargin{:})
        end
    end
end
