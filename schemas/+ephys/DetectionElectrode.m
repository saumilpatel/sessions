%{
ephys.DetectionElectrode (computed) # A electrode of detection

-> ephys.DetectionSet
electrode_number: int unsigned          # the electrode number
---
detection_electrode_filename: varchar(255)                  # Path to the detection electrode
detectionelectrode_ts=CURRENT_TIMESTAMP: timestamp          # automatic timestamp. Do not edit
%}

classdef DetectionElectrode < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.DetectionElectrode');
    end
    
    methods 
        function self = DetectionElectrode(varargin)
            self.restrict(varargin{:})
        end
    end
end
