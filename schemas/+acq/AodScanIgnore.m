%{
acq.AodScanIgnore (manual) # Aod scans
-> acq.AodScan
---
%}


classdef AodScanIgnore < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.AodScanIgnore');
    end
    
    methods 
        function self = AodScanIgnore(varargin)
            self.restrict(varargin{:})
        end
    end
end