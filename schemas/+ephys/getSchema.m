function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema('ephys', 'at-storage.neusc.bcm.tmc.edu', ...
        'ephys', 'jcotton', 'jcotton#1');
end
obj = schemaObject;
