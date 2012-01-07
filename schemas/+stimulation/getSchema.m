function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema('stimulation', 'at-storage.neusc.bcm.tmc.edu', ...
        'stimulation', 'jcotton', 'jcotton#1');
end
obj = schemaObject;
