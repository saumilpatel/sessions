%{
class_discrimination.AnovaBalanced (computed) # Regress orientation over 90 degree range

-> class_discrimination.ClassDiscriminationExperiment
-> ephys.StimTrialGroupAligned
-> class_discrimination.PeriodAnalysis
---
a_samples                : double                 # Number of samples per bin for A regression
b_samples                : double                 # Numbre of samples per bin for B regression
rsquared_a               : double                 # Rsquared of orientation on A trials
rsquared_b               : double                 # Rsquared of orientation on B trials
%}

classdef AnovaBalanced < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('class_discrimination.AnovaBalanced');
        popRel = class_discrimination.CDEType('distribution_type="Uncertain" OR distribution_type="Certain"')*ephys.StimTrialGroupAligned*class_discrimination.PeriodAnalysis;
    end
    
    methods
        function self = AnovaBalanced(varargin)
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
            
            % Categorize orientations
            orientation = floor(orientation / 9);

            n = histc(orientation(selectedA & A_orientation), 0:20);
            n(end) = [];            
            tuple.a_samples = min(n(1:10));
            tuple.a_samples = 11;
            % Equal number of trials from each of the bins
            idx = [];
            for i = 0:9
                ori_idx = find(selectedA & A_orientation & orientation == i);
                ori_idx = ori_idx(randperm(length(ori_idx)));
                ori_idx(tuple.a_samples+1:end) = [];
                idx = [idx; ori_idx];
            end
            [~,~,stats] = anova1(count(idx), orientation(idx),'off')
            v1 = var(count(idx));
            v2 = var(count(idx) - reshape(repmat(stats.means,tuple.a_samples,1),[],1));            
            r2 = (v1 - v2) / v1
            tuple.rsquared_a = r2;
            
            % Compute number of bins for B regression
            n = histc(orientation(~selectedA & ~A_orientation), 0:20);
            n(end) = [];
            tuple.b_samples = min(n(11:20));
            tuple.b_samples = 11;
            idx = [];
            for i = 10:19
                ori_idx = find(~selectedA & ~A_orientation & orientation == i);
                ori_idx = ori_idx(randperm(length(ori_idx)));
                ori_idx(tuple.b_samples+1:end) = [];
                idx = [idx; ori_idx];
            end
            [~,~,stats] = anova1(count(idx), orientation(idx),'off')
            v1 = var(count(idx));
            v2 = var(count(idx) - reshape(repmat(stats.means,tuple.b_samples,1),[],1));            
            r2 = (v1 - v2) / v1
            tuple.rsquared_b = r2;
            
            if isnan(tuple.rsquared_a) || isnan(tuple.rsquared_b)
                return
            end
            
            insert(this,tuple);
        end
        
    end
end
