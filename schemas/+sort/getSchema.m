function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema('sort', 'at-storage.neusc.bcm.tmc.edu', ...
        'sort', 'aecker', 'aecker#1');
end
obj = schemaObject;
