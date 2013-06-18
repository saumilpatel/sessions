%{
acq.AodVolumeIgnore (manual) # Aod scans
-> acq.AodVolume
---
%}


classdef AodVolumeIgnore < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.AodVolumeIgnore');
    end
    
    methods 
        function self = AodVolumeIgnore(varargin)
            self.restrict(varargin{:})
        end
    end
end