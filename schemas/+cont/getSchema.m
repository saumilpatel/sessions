function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    load('djuser.mat');
    schemaObject = dj.Schema('cont', host, 'cont', user, pass);
end
obj = schemaObject;
