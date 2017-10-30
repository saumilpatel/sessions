%{
aod.AodJobs(computed)   # jobs run at the end of each experiment
-> acq.AodScan
<<JobFields>>
%}

classdef AodJobs < dj.Relvar
    properties(Constant)
        table = dj.Table('aod.AodJobs')
    end
    methods
        function self = AodJobs(varargin)
            self.restrict(varargin) 
        end
        
        function run(self)
            % start job management
            s = stimulation.getSchema;
            s.manageJobs(aod.AodJobs);
            
            populate(aod.AodJobs);

            % stop job management 
            s.manageJobs
        end
    end
end
%}
