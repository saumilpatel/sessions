%{
class_discrimination.TuningCurve (computed) # Multiple variable regression for decision and posterior

-> class_discrimination.ClassDiscriminationExperiment
-> ephys.SpikesAligned
-> class_discrimination.PeriodAnalysis
-> class_discrimination.TuningCurveParams
---
orientation_bins=null            : longblob                 # Bins for the orientation
posterior_bins=null              : longblob                 # Bins for the posterior
orientation_curve_a=null         : longblob                 # Orientation tuning curve when A selected
orientation_curve_b=null         : longblob                 # Orientation tuning curve when A selected
posterior_curve_a=null           : longblob                 # Posterior tuning curve when A selected
posterior_curve_b=null           : longblob                 # Posterior tuning curve when A selected
orientation_curve_a_sem=null         : longblob                 # Orientation tuning curve when A selected
orientation_curve_b_sem=null         : longblob                 # Orientation tuning curve when A selected
posterior_curve_a_sem=null           : longblob                 # Posterior tuning curve when A selected
posterior_curve_b_sem=null           : longblob                 # Posterior tuning curve when A selected
tuningcurve_ts=CURRENT_TIMESTAMP : timestamp                # automatic timestamp. Do not edit
%}

classdef TuningCurve < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('class_discrimination.TuningCurve');
        popRel = class_discrimination.ClassDiscriminationExperiment*ephys.SpikesAligned* ...
            class_discrimination.PeriodAnalysis*class_discrimination.TuningCurveParams;
    end
    
    methods
        function self = TuningCurve(varargin)
            self.restrict(varargin{:})
        end
        
        function plot(this)
            assert(count(this) == 1, 'Only call for one TC');
            dat = fetch(this,'*');

            %subplot(211);
            cla
            hold on
            errorbar(dat.orientation_bins,dat.orientation_curve_a,dat.orientation_curve_a_sem,'r');
            errorbar(dat.orientation_bins,dat.orientation_curve_b,dat.orientation_curve_b_sem,'g');
            
            %subplot(212);
            %cla
            %hold on
            %errorbar(dat.posterior_bins,dat.posterior_curve_a,dat.posterior_curve_a_sem,'r');
            %errorbar(dat.posterior_bins,dat.posterior_curve_b,dat.posterior_curve_b_sem,'g');
        end

        function plotMean(this)
            dat = fetch(this,'*');
            
            curve_a = cat(1,dat.orientation_curve_a);
            curve_b = cat(1,dat.orientation_curve_b);

            norm = nanmean([curve_a curve_b],2);
            
            curve_a = bsxfun(@rdivide, curve_a, norm);
            sem_a = nanstd(curve_a,[],1) / sqrt(size(curve_a,1));
            curve_a = nanmedian(curve_a,1);
            
            curve_b = bsxfun(@rdivide, curve_b, norm);
            sem_b = nanstd(curve_b,[],1) / sqrt(size(curve_b,1));
            curve_b = nanmedian(curve_b,1);
            cla; hold on
            errorbar(dat(1).orientation_bins, curve_a,sem_a, 'k');
            errorbar(dat(1).orientation_bins, curve_b,sem_b, 'k--');
            xlabel('Orientation (deg)');
            ylabel('Normalized firing rate');
        end

        function plotMeanPost(this)
            dat = fetch(this,'*');
            
            curve_a = cat(1,dat.posterior_curve_a);
            curve_b = cat(1,dat.posterior_curve_b);

            norm = nanmean([curve_a curve_b],2);
            
            curve_a = bsxfun(@rdivide, curve_a, norm);
            sem_a = nanstd(curve_a,[],1) / sqrt(size(curve_a,1));
            curve_a = nanmean(curve_a,1);
            
            curve_b = bsxfun(@rdivide, curve_b, norm);
            sem_b = nanstd(curve_b,[],1) / sqrt(size(curve_b,1));
            curve_b = nanmean(curve_b,1);

            plot(dat(1).posterior_bins, curve_a, 'r', ...
                dat(1).posterior_bins, curve_a + sem_a, 'r', ...
                dat(1).posterior_bins, curve_a - sem_a, 'r', ...
                dat(1).posterior_bins, curve_b, 'g', ...
                dat(1).posterior_bins, curve_b + sem_b, 'g', ...
                dat(1).posterior_bins, curve_b - sem_b, 'g');
            xlabel('p(A | \theta)');
            ylabel('Mean normalized firing rate');
        end
    end
    
    methods (Access=protected)
        function makeTuples( this, key )
            % Compute the class tuning for this cell
            tuple = key;
            
            [selected_class orientation posterior spikes] = ...
                fetchn(class_discrimination.ClassDiscriminationTrial(key) * ephys.SpikesAlignedTrial(key),...
                'selected_class', 'orientation', 'posterior_a', 'spikes_aligned');
            
            selectedA = cellfun(@(x) x=='A', selected_class);
            
            if strcmp(key.regression_time_period, 'Cue')
                tframe = [0 500] + key.regression_time_latency;
            elseif strcmp(key.regression_time_period, 'Memory')
                tframe = [500 1500] + key.regression_time_latency;
            else
                error('Unsupported period');
            end
            
            count = cellfun(@(x) sum(x >= tframe(1) & x <= tframe(2)) * 1000 / (tframe(2) - tframe(1)), spikes);
            
            orientation_bins = quantile(orientation,linspace(0, 1, tuple.bins+1));
            posterior_bins = quantile(posterior, linspace(0, 1, tuple.bins+1));
            
            for i = 1:length(orientation_bins)-1
                neq_a = sqrt(sum(orientation >= orientation_bins(i) & orientation <= orientation_bins(i+1) & selectedA));
                neq_b = sqrt(sum(orientation >= orientation_bins(i) & orientation <= orientation_bins(i+1) & ~selectedA));

                tuple.orientation_curve_a(i) = mean(count(orientation >= orientation_bins(i) & orientation <= orientation_bins(i+1) & selectedA));
                tuple.orientation_curve_b(i) = mean(count(orientation >= orientation_bins(i) & orientation <= orientation_bins(i+1) & ~selectedA));

                tuple.orientation_curve_a_sem(i) = std(count(orientation >= orientation_bins(i) & orientation <= orientation_bins(i+1) & selectedA)) / neq_a;
                tuple.orientation_curve_b_sem(i) = std(count(orientation >= orientation_bins(i) & orientation <= orientation_bins(i+1) & ~selectedA)) / neq_b;
            end
            for i = 1:length(posterior_bins)-1
                neq_a = sqrt(sum(posterior >= posterior_bins(i) & posterior <= posterior_bins(i+1) & selectedA));
                neq_b = sqrt(sum(posterior >= posterior_bins(i) & posterior <= posterior_bins(i+1) & ~selectedA));

                tuple.posterior_curve_a(i) = mean(count(posterior >= posterior_bins(i) & posterior <= posterior_bins(i+1) & selectedA));
                tuple.posterior_curve_b(i) = mean(count(posterior >= posterior_bins(i) & posterior <= posterior_bins(i+1) & ~selectedA));

                tuple.posterior_curve_a_sem(i) = std(count(posterior >= posterior_bins(i) & posterior <= posterior_bins(i+1) & selectedA)) / neq_a;
                tuple.posterior_curve_b_sem(i) = std(count(posterior >= posterior_bins(i) & posterior <= posterior_bins(i+1) & ~selectedA)) / neq_b;
            end
            
            tuple.orientation_bins = (orientation_bins(1:end-1) + orientation_bins(2:end)) / 2;
            tuple.posterior_bins = (posterior_bins(1:end-1) + posterior_bins(2:end)) / 2;

            insert(this,tuple);
        end
        
    end
end