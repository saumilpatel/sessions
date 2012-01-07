function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema('sessions', 'at-storage.neusc.bcm.tmc.edu', ...
        'acq', 'jcotton', 'jcotton#1');
%    schemaObject = dj.Schema('sessions', 'localhost', ...
%        'acq', 'root', '');

end
obj = schemaObject;
