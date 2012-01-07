%{
cont.Mua (imported) # mua (energy in 600-6K band) trace

->acq.Ephys
---
mua_file : VARCHAR(255) # name of file containg MUA
%}

classdef Mua < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('cont.Mua');
        popRel = acq.Ephys;
    end
    
    methods 
        function self = Mua(varargin)
            self.restrict(varargin{:})
        end
        
        
        function makeTuples(self, key)
            tuple = key;
            
            % TODO
            error('TODO')
            
            self.insert(tuple);
        end
    end
end
