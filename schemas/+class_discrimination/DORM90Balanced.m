%{
class_discrimination.DORM90Balanced (computed) # Regress orientation over 90 degree range

-> class_discrimination.ClassDiscriminationExperiment
-> ephys.StimTrialGroupAligned
-> class_discrimination.PeriodAnalysis
---
baseline_firing_a        : double                 # The average firing rate when decided A
baseline_firing_b        : double                 # The average firing rate when decided B
orientation_modulation_a : double                 # Modulation by orientation on A trials
orientation_modulation_b : double                 # Modulation by orientation on B trials
a_samples                : double                 # Number of samples per bin for A regression
b_samples                : double                 # Numbre of samples per bin for B regression
rsquared_a               : double                 # Rsquared of orientation on A trials
rsquared_b               : double                 # Rsquared of orientation on B trials
fstat_pval_a             : double                 # FStat PVal
fstat_pval_b             : double                 # FStat PVal
ttest_pval_a             : double                 # TTest PVal
ttest_pval_b             : double                 # TTest PVal
%}

classdef DORM90Balanced < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('class_discrimination.DORM90Balanced');
        popRel = class_discrimination.ClassDiscriminationExperiment*ephys.StimTrialGroupAligned*class_discrimination.PeriodAnalysis;
    end
    
    methods
        function self = DORM90Balanced(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            % Compute the class tuning for this cell
            tuple = key;
            
            [cue_class selected_class orientation posterior spikes] = ...
                fetchn(class_discrimination.ClassDiscriminationTrial(key) * ephys.SpikesAligned(key),...
                'stimulus_class', 'selected_class', 'orientation', 'posterior_a', 'spikes_aligned');
            
            selectedA = cellfun(@(x) x=='A', selected_class);
            A_orientation = ~(orientation > 90 & orientation < 270);
            
            if strcmp(key.regression_time_period, 'Cue')
                tframe = [0 500] + key.regression_time_latency;
            elseif strcmp(key.regression_time_period, 'Memory')
                tframe = [500 1500] + key.regression_time_latency;
            else
                error('Unsupported period');
            end
            
            count = cellfun(@(x) sum(x >= tframe(1) & x <= tframe(2)), spikes);
            
            if mean(orientation) > 180
                % The certain experiment is from 180 to 360
                orientation = 360 - orientation;
            end
            
            nbins = 20;
            bins = linspace(0, 180.01, nbins+1)
            n = histc(orientation(selectedA & A_orientation), bins);
            n(end) = [];            
            tuple.a_samples = min(n(1:nbins/2));
            
            % Equal number of trials from each of the bins
            idx = [];
            for i = 1:10
                ori_idx = find(selectedA & A_orientation & (orientation >= bins(i)) & orientation < bins(i+1));
                ori_idx = ori_idx(randperm(length(ori_idx)));
                ori_idx(tuple.a_samples+1:end) = [];
                idx = [idx; ori_idx];
            end
            stats = regstats(count(idx), orientation(idx),'linear',{'beta','rsquare','fstat','tstat'});            
            tuple.baseline_firing_a = stats.beta(1);
            tuple.orientation_modulation_a = stats.beta(2); 
            tuple.rsquared_a = stats.rsquare;
            tuple.fstat_pval_a = stats.fstat.pval;
            tuple.ttest_pval_a = stats.tstat.pval(2);
            
            % Compute number of bins for B regression
            n = histc(orientation(~selectedA & ~A_orientation), bins);
            n(end) = [];
            tuple.b_samples = min(n(nbins/2+1:end));
            idx = [];
            for i = 1:10
                ori_idx = find(~selectedA & ~A_orientation & (orientation >= bins(10+i)) & (orientation < bins(10+1+i)));
                ori_idx = ori_idx(randperm(length(ori_idx)));
                ori_idx(tuple.b_samples+1:end) = [];
                idx = [idx; ori_idx];
            end
            stats = regstats(count(idx), orientation(idx),'linear',{'beta','rsquare','fstat','tstat'});            
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
