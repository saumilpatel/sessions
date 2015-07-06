%{
acq.ArrayInfo (manual) # Specifications for recording arrays used

array_id                     : tinyint unsigned       # identifier for array
---
array_name                   : varchar(60)            # name of array
num_shanks                   : int unsigned           # number of shanks on array
num_channels                 : int unsigned           # number of channels on array
vendor                       : varchar(30)            # name of product vendor
contact_area = NULL          : double                 # area in square microns of contact sites on array
contact_material = NULL      : varchar(30)            # contact site material
%}

classdef ArrayInfo < dj.Relvar
    
    methods
        function order = channelOrder(self, coord, shank)
            % Sort channels
            %   order = layout.channelOrder('x') returns the channel
            %   indices ordered by their x coordinate (analogous for y).
            %
            %   order = layout.channelOrder('yx') orders first by y, then
            %   by x.
            
            assert(all(ismember(coord, 'xy')), 'Input must specify combination of x and y!')
            if nargin < 3, shank = 1; end
            [x, y] = fetchn(self * acq.ArrayChannels & struct('shank_num', shank), 'x_coord', 'y_coord');
            m = max(max(x), max(y));
            k = 0;
            nc = numel(coord);
            for i = 1 : nc
                k = k + m ^ (nc - i) * eval(coord(i));
            end
            [~, order] = sort(k);
        end
    end
    
end
