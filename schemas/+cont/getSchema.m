function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    load('djuser.mat');
    schemaObject = dj.Schema('cont', 'at-storage.neusc.bcm.tmc.edu', ...
        'cont', user, pass);
end
obj = schemaObject;
