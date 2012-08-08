%{
class_discrimination.DecisionOrientationRegressionModel (computed) # Regress orientation out for each decision

-> class_discrimination.ClassDiscriminationExperiment
-> ephys.SpikesAligned
-> class_discrimination.PeriodAnalysis
---
baseline_firing_a        : double                 # The average firing rate when decided A
baseline_firing_b        : double                 # The average firing rate when decided B
orientation_modulation_a : double                 # Modulation by orientation on A trials
orientation_modulation_b : double                 # Modulation by orientation on B trials
rsquared_a               : double                 # Rsquared of orientation on A trials
rsquared_b               : double                 # Rsquared of orientation on B trials
fstat_pval_a             : double                 # FStat PVal
fstat_pval_b             : double                 # FStat PVal
ttest_pval_a             : double                 # TTest PVal
ttest_pval_b             : double                 # TTest PVal
%}

classdef DecisionOrientationRegressionModel < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('class_discrimination.DecisionOrientationRegressionModel');
        popRel = class_discrimination.ClassDiscriminationExperiment*ephys.SpikesAligned*class_discrimination.PeriodAnalysis;
    end
    
    methods
        function self = DecisionOrientationRegressionModel(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)
        function makeTuples( this, key )
            % Compute the class tuning for this cell
            tuple = key;
            
            [cue_class selected_class orientation posterior spikes] = ...
                fetchn(class_discrimination.ClassDiscriminationTrial(key) * ephys.SpikesAlignedTrial(key),...
                'stimulus_class', 'selected_class', 'orientation', 'posterior_a', 'spikes_aligned');
            
            selectedA = cellfun(@(x) x=='A', selected_class);
            
            if strcmp(key.regression_time_period, 'Cue')
                tframe = [0 500] + key.regression_time_latency;
            elseif strcmp(key.regression_time_period, 'Memory')
                tframe = [500 1500] + key.regression_time_latency;
            else
                error('Unsupported period');
            end
            
            count = cellfun(@(x) sum(x >= tframe(1) & x <= tframe(2)), spikes);
            
            stats = regstats(count(selectedA), orientation(selectedA),'linear',{'beta','rsquare','fstat','tstat'});            
            tuple.baseline_firing_a = stats.beta(1);
            tuple.orientation_modulation_a = stats.beta(2); 
            tuple.rsquared_a = stats.rsquare;
            tuple.fstat_pval_a = stats.fstat.pval;
            tuple.ttest_pval_a = stats.tstat.pval(2);
            
            stats = regstats(count(~selectedA), orientation(~selectedA),'linear',{'beta','rsquare','fstat','tstat'});            
            tuple.baseline_firing_b = stats.beta(1);
            tuple.orientation_modulation_b = stats.beta(2); 
            tuple.rsquared_b = stats.rsquare
            tuple.fstat_pval_b = stats.fstat.pval;
            tuple.ttest_pval_b = stats.tstat.pval(2);

            if isnan(tuple.rsquared_a) 
                tuple.rsquared_a = 0;
                tuple.fstat_pval_a = 1;
                tuple.ttest_pval_a = 1;
            end
            if isnan(tuple.rsquared_b) 
                tuple.rsquared_b = 0;
                tuple.fstat_pval_b = 1;
                tuple.ttest_pval_b = 1;
            end
            
            insert(this,tuple);
        end
        
    end
end
