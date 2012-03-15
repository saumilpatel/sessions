function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    acq.getSchema();
    schemaObject = dj.Schema(dj.conn, 'class_discrimination', 'james_ephys');
end
obj = schemaObject;
