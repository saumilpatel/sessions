%{
sort.Electrodes (imported) # clustering for one electrode

->sort.Sets
->detect.Electrodes
---
%}

classdef Electrodes < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('sort.Electrodes');
        popRel = detect.Electrodes * sort.Sets;
    end
    
    methods 
        function self = Electrodes(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            self.insert(key);
        end
    end
end
