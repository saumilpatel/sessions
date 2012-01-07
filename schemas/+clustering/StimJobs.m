%{
clustering.StimJobs(computed)   # jobs run at the end of each experiment
-> stimulation.StimTrialGroup
<<JobFields>>
%}

classdef StimJobs < dj.Relvar
    properties(Constant)
        table = dj.Table('clustering.StimJobs')
    end
    methods
        function self = StimJobs(varargin)
            self.restrict(varargin) 
        end
        
        function run(self)
            % start job management
            s = class_discrimination.getSchema;
            s.manageJobs(this);
            
            populate(class_discrimination.ClassDiscriminationExperiment);
            populate(class_discrimination.ClassificationNeuron);
            populate(class_discrimination.RegressionModel);
            populate(class_discrimination.ClassDiscriminationHMM);

            % stop job management 
            s.manageJobs
        end
    end
end
%}