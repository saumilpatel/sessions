
%{
class_discrimination.ClassDiscriminationExperiment (computed) # Contains information relavent for behavior classification

-> stimulation.StimTrialGroup
---
distribution_entropy          : double # entropy of all the trials used
distribution_theta            : longblob # sample evaluated at
distribution_a                : longblob # distribution for class A
distribution_b                : longblob # distribution for class B
range_a                       : double   # Number of degrees with support for A
range_b                       : double   # Number of degrees with support for B
classdiscriminationexperiment_ts=CURRENT_TIMESTAMP: timestamp# automatic timestamp. Do not edit
%}

classdef ClassDiscriminationExperiment < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('class_discrimination.ClassDiscriminationExperiment');
        popRel = sessions.Stimulation('exp_type="ClassDiscrimination" AND correct_trials > 400')*stimulation.StimTrialGroup
    end
    
    methods 
        function self = ClassDiscriminationExperiment(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            % Get additional information for each trial
            tuple = key;
            constants = fetch1(stimulation.StimTrialGroup(key), 'stim_constants');
            theta = 0:0.1:360;
            dA = eval(constants.distributionA);
            dB = eval(constants.distributionB);
            post = dA ./ (dA + dB);
            likelihood = (dA + dB) / sum(dA + dB);
            
            tuple.distribution_entropy = -(post .* log2(post)) * likelihood';
            tuple.distribution_theta = theta;
            tuple.distribution_a = dA;
            tuple.distribution_b = dB;
            
            t = linspace(0,1,100000);
            for i = 1:length(t)
                q = dA * (dA > t(i))';
                r(i) = sum(dA > t(i)) * mean(diff(theta));
                if(q < 0.95)
                    tuple.range_a = r(i-1);
                    break;
                end
            end
            for i = 1:length(t)
                q = dB * (dB > t(i))';
                r(i) = sum(dB > t(i)) * mean(diff(theta));
                if(q < 0.95)
                    tuple.range_b = r(i-1);
                    break;
                end
            end
            
            
            insert(this,tuple);
            tuples = dj.utils.structJoin(key, fetch(stimulation.StimTrials(key,'valid_trial=TRUE')));
            
            for tuple = tuples'
                makeTuples(class_discrimination.ClassDiscriminationTrial,tuple);
            end
        end
        
    end
end