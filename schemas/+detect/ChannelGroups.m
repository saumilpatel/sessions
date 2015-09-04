%{
detect.ChannelGroups (manual) # Channel groups

-> detect.ChannelGroupParams
electrode_num   : tinyint unsigned      # group number (called electrode for compatibility)
---
%}

classdef ChannelGroups < dj.Relvar & dj.AutoPopulate

    properties (Constant)
        popRel = detect.ChannelGroupParams;
    end

    methods (Access = protected)
        function makeTuples(self, key)
            [count, stride] = fetch1(detect.ChannelGroupParams & key, 'count', 'stride');
            channels = channelOrder(acq.ArrayInfo & key, 'y');
            idx = bsxfun(@plus, 1 : count, (0 : stride : numel(channels) - count)');
            groups = channels(idx);
            n = size(groups, 1);
            for i = 1 : n
                tuple = key;
                tuple.electrode_num = i;
                self.insert(tuple);
                for c = groups(i, :)
                    tuple.channel_num = c;
                    insert(detect.ChannelGroupMembers, tuple)
                end
            end
        end
    end
end
