%{
sort.AutoJobs (computed) # automatic clustering jobs
->detect.Electrodes
---
<<JobFields>>
%}

classdef AutoJobs < dj.Relvar & dj.Jobs
    properties(Constant)
        table = dj.Table('sort.AutoJobs');
    end
    
    methods 
        function self = AutoJobs(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Static)
        function job(key)
            populate(sort.Auto, key)
        end
    end
end
