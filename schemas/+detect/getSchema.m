function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema('detect', 'at-storage.neusc.bcm.tmc.edu', ...
        'detect', 'aecker', 'aecker#1');
end
obj = schemaObject;
