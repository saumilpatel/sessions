function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    load('djuser');
    schemaObject = dj.Schema('sessions', 'at-storage.neusc.bcm.tmc.edu', ...
        'acq', user, pass);
end
obj = schemaObject;
