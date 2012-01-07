function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema('cont', 'at-storage.neusc.bcm.tmc.edu', ...
        'cont', 'aecker', 'aecker#1');
end
obj = schemaObject;
