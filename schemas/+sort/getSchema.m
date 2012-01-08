function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    load('djuser');
    schemaObject = dj.Schema('sort', 'at-storage.neusc.bcm.tmc.edu', ...
        'sort', user, pass);
end
obj = schemaObject;