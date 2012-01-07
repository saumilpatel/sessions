%{
stimulation.StimJobs(computed)   # jobs run at the end of each experiment
-> sessions.Stimulation
<<JobFields>>
%}

classdef StimJobs < dj.Relvar
    properties(Constant)
        table = dj.Table('stimulation.StimJobs')
    end
    methods
        function self = StimJobs(varargin)
            self.restrict(varargin) 
        end
        
        function run(self)
            % start job management
            s = stimulation.getSchema;
            s.manageJobs(stimulation.StimJobs);
            
            populate(stimulation.StimTrialGroup);

            % stop job management 
            s.manageJobs
        end
    end
end
%}