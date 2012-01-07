%{
sort.Sets (imported) # Set of electrodes to cluster

-> sort.Params
---
sort_set_path : VARCHAR(255) # folder containing spike sorting files
%}

classdef Sets < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('sort.Sets');
        popRel = sort.Params;
    end
    
    methods
        function self = Sets(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            detectPath = fetch1(detect.Sets(key), 'detect_set_path');
            sortMethod = fetch1(sort.Methods(key), 'sort_method_name');
            key.sort_set_path = [detectPath '/' sortMethod];
            self.insert(key);
        end
    end
end
