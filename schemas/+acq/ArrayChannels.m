%{
acq.ArrayChannels (manual) # Specifications for recording arrays used

-> acq.ArrayInfo
channel_num             : tinyint unsigned  # channel number
---
-> acq.ArrayShanks
x_coord                 : double            # channel x (lateral) position in microns
y_coord                 : double            # channel y (depth) position in microns
z_coord                 : double            # channel z (ant-post) position in microns

%}

classdef ArrayChannels < dj.Relvar
end
