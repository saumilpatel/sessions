function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema('clustering', 'at-storage.neusc.bcm.tmc.edu', ...
        'james_ephys', 'jcotton', 'jcotton#1');
end
obj = schemaObject;
