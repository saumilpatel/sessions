%{
detect.ChannelGroupParams (manual) # Parameters for grouping channels

-> acq.ArrayInfo
---
count   : tinyint unsigned  # number of channels per group
stride  : tinyint unsigned  # stride for overlapping groups
---
%}

classdef ChannelGroupParams < dj.Relvar
end
