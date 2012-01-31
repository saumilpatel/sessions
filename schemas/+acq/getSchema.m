function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    load('djuser.mat');
    schemaObject = dj.Schema('acq', host, 'acq', user, pass);
end
obj = schemaObject;
