function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    load('djuser');
    schemaObject = dj.Schema('detect', 'at-storage.neusc.bcm.tmc.edu', ...
        'detect', user, pass);
end
obj = schemaObject;
