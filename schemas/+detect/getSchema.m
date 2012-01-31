function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    load('djuser');
    schemaObject = dj.Schema('detect', host, 'detect', user, pass);
end
obj = schemaObject;
