%{
cont.Lfp (imported) # local field potential trace

->acq.Ephys
---
lfp_file : VARCHAR(255) # name of file containg LFP
%}

classdef Lfp < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('cont.Lfp');
        popRel = acq.Ephys;
    end
    
    methods 
        function self = Lfp(varargin)
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
