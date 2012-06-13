%{
aod.TraceQuality (imported) # A scan site

->aod.QualitySet
->aod.Traces
---
pre_position_distance  : double   # Distance from center of cell to click
post_position_distance : double   # Distance from center of cell to click
snr                    : double   # SNR based on the photon rate
%}

classdef TraceQuality < dj.Relvar
    properties(Constant)
        table = dj.Table('aod.TraceQuality');
    end
    
    methods 
        function self = TraceQuality(varargin)
            self.restrict(varargin{:})
        end
    end
end
