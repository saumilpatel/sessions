%{
sort.MultiUnit (imported) # provide transparent access to multi unit

->sort.Electrodes
---
%}

classdef MultiUnit < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('sort.MultiUnit');
        popRel = sort.Electrodes * sort.Methods('sort_method_name = "MultiUnit"');
    end
    
    methods 
        function self = MultiUnit(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            self.insert(key);
        end
    end
end
