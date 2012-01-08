function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    load('djuser.mat');
    schemaObject = dj.Schema('acq', 'at-storage.neusc.bcm.tmc.edu', ...
        'acq', user, pass);
end
obj = schemaObject;
