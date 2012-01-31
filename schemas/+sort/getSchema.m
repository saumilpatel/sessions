function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    load('djuser');
    schemaObject = dj.Schema('sort', host, 'sort', user, pass);
end
obj = schemaObject;
