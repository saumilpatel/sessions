%{
detect.NoiseArtifacts (imported) # spike detection for one electrode
      
-> detect.Electrodes
artifact_start  : double    # start of artifact period
---
artifact_end    : double    # end of artifact period
%}

classdef NoiseArtifacts < dj.Relvar
    properties(Constant)
        table = dj.Table('detect.NoiseArtifacts');
    end
    
    methods 
        function self = NoiseArtifacts(varargin)
            self.restrict(varargin{:})
        end
    end
end
