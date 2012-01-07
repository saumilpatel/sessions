%{
ephys.LfpExtraction (computed) # Indicates when lfp extracted

-> sessions.Ephys
---
lfp_path                    : varchar(255)                  # Path to the lfp
lfpextraction_ts=CURRENT_TIMESTAMP: timestamp               # automatic timestamp. Do not edit
%}

classdef LfpExtraction < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.LfpExtraction');
    end
    
    methods 
        function self = LfpExtraction(varargin)
            self.restrict(varargin{:})
        end
    end
end
