function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    sort.getSchema();
    schemaObject = dj.Schema(dj.conn, 'aod', 'aod');
end
obj = schemaObject;
