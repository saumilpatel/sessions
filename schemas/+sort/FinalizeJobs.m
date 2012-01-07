%{
sort.FinalizeJobs (computed) # clustering finalization jobs
->sort.Manual
---
<<JobFields>>
%}

classdef FinalizeJobs < dj.Relvar & dj.Jobs
    properties(Constant)
        table = dj.Table('sort.FinalizeJobs');
    end
    
    methods 
        function self = FinalizeJobs(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Static)
        function job(key)
            populate(sort.Finalize, key)
            populate(sort.ClusterInfo, key)    % should this go into sort.Finalize.makeTuples?
            populate(sort.SetsCompleted, key)
        end
    end
end
