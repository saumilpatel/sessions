function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema('acq', 'at-storage.neusc.bcm.tmc.edu', ...
        'acq', 'aecker', 'aecker#1');
end
obj = schemaObject;
