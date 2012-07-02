%{
aod.TraceSet (imported) # A scan site

->acq.AodScan
->acq.SessionsCleanup
---
num_cells             : int unsigned     # Number of cells in the data set
num_planes            : int unsigned     # Number of motion planes
%}

classdef TraceSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('aod.TraceSet');
        popRel = acq.AodScan & acq.SessionsCleanup
    end
    
    methods 
        function self = TraceSet(varargin)
            self.restrict(varargin{:})
        end
    
        function makeTuples( this, key )
            % Import a spike set
            tuple = key;

            asr = getFile(acq.AodScan(key), 'Functional');
            try
                amr = getFile(acq.AodScan(key), 'Motion');
                tuple.num_planes = amr.planes;
            catch
                tuple.num_planes = 0;
            end
            
            tuple.num_cells = size(asr,2);
            insert(this,tuple);
            
            makeTuples(aod.Traces, key, asr);
        end
    end
end
