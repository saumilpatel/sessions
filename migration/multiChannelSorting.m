% Migration script for database updates related to spike sorting of
% multi-channel probes. Run this scrtipt to update the database tables
% after updating the code.
%
% AE 2015-09-01


%% Create array info tables
acq.ArrayInfo
acq.ArrayShanks
acq.ArrayChannels


%% Insert arrays
insert(acq.ArrayInfo, struct('array_id', 0, 'array_name', 'unknown', 'num_shanks', 0, 'num_channels', 0, 'vendor', 'n/a'))

insert(acq.ArrayInfo, struct('array_id', 1, 'array_name', 'V1x32-Edge-10mm-60-177-V32', 'num_shanks', 1, 'num_channels', 32, 'vendor', 'NeuroNexus', 'contact_area', 177, 'contact_material', 'Iridium'))
insert(acq.ArrayShanks, struct('array_id', 1, 'shank_num', 1, 'num_channels', 32))
for i = 1 : 32
    insert(acq.ArrayChannels, struct('array_id', 1, 'channel_num', i, 'shank_num', 1, 'x_coord', 0, 'y_coord', 60 * (i - 1), 'z_coord', 0))
end

insert(acq.ArrayInfo, struct('array_id', 2, 'array_name', 'V1x32-Poly2-15mm-50s-177', 'num_shanks', 1, 'num_channels', 32, 'vendor', 'NeuroNexus', 'contact_area', 177, 'contact_material', 'Iridium'))
insert(acq.ArrayShanks, struct('array_id', 2, 'shank_num', 1, 'num_channels', 32))
x = [zeros(1, 16), ones(1, 16) * sqrt(3) / 2 * 50];
y = [150 : 50 : 750, 100, 50, 0, 25, 75, 125, 775 : -50 : 175];
for i = 1 : 32
    insert(acq.ArrayChannels, struct('array_id', 2, 'channel_num', i, 'shank_num', 1, 'x_coord', x(i), 'y_coord', y(i), 'z_coord', 0))
end

insert(acq.ArrayInfo, struct('array_id', 3, 'array_name', 'V1x32-Edge-15mm-100-177', 'num_shanks', 1, 'num_channels', 32, 'vendor', 'NeuroNexus', 'contact_area', 177, 'contact_material', 'Iridium'))
insert(acq.ArrayShanks, struct('array_id', 3, 'shank_num', 1, 'num_channels', 32))
for i = 1 : 32
    insert(acq.ArrayChannels, struct('array_id', 3, 'channel_num', i, 'shank_num', 1, 'x_coord', 0, 'y_coord', 100 * (i - 1), 'z_coord', 0))
end


%% Update acq.EphysTypes table

% NOTE: answer 'no' to all prompts asking whether to update the table
%       declaration! The changes to the table declaratons are part of this
%       patch.

addAttribute(acq.EphysTypes, 'array_id : tinyint unsigned # identifier for array', 'AFTER ephys_task')

% Add foreign key. Due to a MySQL bug the following does not work
% addForeignKey(acq.EphysTypes, acq.ArrayInfo)
conn = dj.conn;
conn.query('ALTER TABLE `acq`.`#ephys_types` ADD CONSTRAINT `#ephys_types_ibfk_2` FOREIGN KEY (array_id) REFERENCES `acq`.`array_info` (array_id) ON UPDATE CASCADE ON DELETE RESTRICT')

alterAttribute(acq.EphysTypes, 'detect_method_num', 'default_detect_method_num : tinyint unsigned # default detect method')
alterAttribute(acq.EphysTypes, 'sort_method_num', 'default_sort_method_num : tinyint unsigned # default spike sorting method')


%% Assign proper array_ids
[names, ids] = fetchn(acq.ArrayInfo & 'array_id > 0', 'array_name', 'array_id');
for i = 1 : numel(names)
    keys = fetch(acq.EphysTypes & struct('ephys_task', names{i}));
    for k = keys'
        update(acq.EphysTypes & k, 'array_id', ids(i))
    end
end


%% Create channel groups
detect.ChannelGroupParams
detect.ChannelGroups
detect.ChannelGroupMembers
insert(detect.ChannelGroupParams, struct('array_id', 1, 'count', 6, 'stride', 2))
insert(detect.ChannelGroupParams, struct('array_id', 2, 'count', 6, 'stride', 2))
populate(detect.ChannelGroups)
