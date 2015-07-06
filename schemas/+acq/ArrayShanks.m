%{
acq.ArrayShanks (manual) # Specifications for recording arrays used

-> acq.ArrayInfo
shank_num       : tinyint unsigned      # shank number on array
---
num_channels    : tinyint unsigned      # number of channels on shank
%}

classdef ArrayShanks < dj.Relvar
end
