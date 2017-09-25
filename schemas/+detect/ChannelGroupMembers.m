%{
detect.ChannelGroupMembers (manual) # Channel group membership table

-> detect.ChannelGroups
-> acq.ArrayChannels
---
%}

classdef ChannelGroupMembers < dj.Relvar
end
