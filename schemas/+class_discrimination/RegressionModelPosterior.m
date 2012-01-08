%{
class_discrimination.RegressionModelPosterior (computed) # Multiple variable regression for decision and posterior

-> class_discrimination.ClassDiscriminationExperiment
-> ephys.SpikesAligned
-> class_discrimination.PeriodAnalysis
---
baseline_firing         : double                 # The average firing rate
decision_modulation     : double                 # The amount of firing by decision
cue_class_modulation    : double                 # The remaining modulation by class
posterior_modulation    : double                 # Modulation by the posterior
baseline_firing_pval    : double                 # P-value for baseline
decision_modulation_pval    : double                 # P-value for  decision
cue_class_modulation_pval   : double                 # P-value for class
posterior_modulation_pval   : double                 # P-value for posterior
fstat_pval              : double                 # Overall p-value
rsquare                 : double                 # Overall r-squared value
%}

classdef RegressionModelPosterior < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('class_discrimination.RegressionModelPosterior');
        popRel = class_discrimination.ClassDiscriminationExperiment*ephys.SpikesAligned*class_discrimination.PeriodAnalysis;
    end
    
    methods
        function self = RegressionModelPosterior(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            % Compute the class tuning for this cell
            tuple = key;
            
            [cue_class selected_class posterior spikes] = ...
                fetchn(class_discrimination.ClassDiscriminationTrial(key) * ephys.SpikesAlignedTrial(key),...
                'stimulus_class', 'selected_class', 'posterior_a', 'spikes_aligned');
            
            cueA = cellfun(@(x) x=='A', cue_class) - 0.5;
            selectedA = cellfun(@(x) x=='A', selected_class) - 0.5;
            
            if strcmp(key.regression_time_period, 'Cue')
                tframe = [0 500] + key.regression_time_latency;
            elseif strcmp(key.regression_time_period, 'Memory')
                tframe = [500 1500] + key.regression_time_latency;
            else
                error('Unsupported period');
            end
            
            count = cellfun(@(x) sum(x >= tframe(1) & x <= tframe(2)), spikes);
            
            if(sum(count) == 0)
                return;
            end
            posterior = (posterior - 0.5) / std(posterior);
            stats = regstats(count,[selectedA posterior],'linear',{'beta','rsquare','tstat','fstat'});
            b = stats.beta;
            
            tuple.cue_class_modulation = 0; %b(2);
            tuple.decision_modulation = b(2);
            tuple.posterior_modulation = b(3);
            tuple.baseline_firing = b(1);

            tuple.cue_class_modulation_pval = 0; %stats.tstat.pval(2);
            tuple.decision_modulation_pval = stats.tstat.pval(2);
            tuple.posterior_modulation_pval = stats.tstat.pval(3);
            tuple.baseline_firing_pval = stats.tstat.pval(1);
            
            tuple.fstat_pval = stats.fstat.pval;
            tuple.rsquare = stats.rsquare;

            insert(this,tuple);
        end
        
    end
end
