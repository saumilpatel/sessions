%{
detect.NoiseArtifacts (imported) # detected noise artifacts in recordings
      
-> detect.Electrodes
artifact_start      : double    # start of noise artifact period
---
artifact_end        : double    # end of noise artifact period
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
