%{
ephys.DetectionSetParam (manual) # Detection methods

-> sessions.Ephys
detection_method: enum('Utah')          # The method to use for detection
---
ephys_processed_directory   : varchar(255)                  # Output directory for processing
detectionsetparam_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef DetectionSetParam < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.DetectionSetParam');
    end
    
    methods 
        function self = DetectionSetParam(varargin)
            self.restrict(varargin{:})
        end
    end
end
