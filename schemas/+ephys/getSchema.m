function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    load('djuser');
    schemaObject = dj.Schema('ephys', 'at-storage.neusc.bcm.tmc.edu', ...
        'ephys', user, pass);
end
obj = schemaObject;
