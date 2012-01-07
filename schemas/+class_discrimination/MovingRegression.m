%{
class_discrimination.MovingRegression (computed) # Multiple variable regression for decision and posterior

-> class_discrimination.ClassDiscriminationExperiment
-> ephys.StimTrialGroupAligned
---
time_bins=null       : longblob          # Time bins for the regression
modulation_a=null    : longblob            # Spikes difference over time
modulation_b=null    : longblob            # Spikes difference over time
rsquared_a=null      : longblob            # Spikes difference over time
rsquared_b=null      : longblob            # Spikes difference over time
null_modulation_a=null    : longblob            # Spikes difference over time
null_modulation_b=null    : longblob            # Spikes difference over time
null_rsquared_a=null      : longblob            # Spikes difference over time
null_rsquared_b=null      : longblob            # Spikes difference over time
a_samples                 : int unsigned        # Number of bins for A regressions
b_samples                 : int unsigned        # Number of bins for B regressions
%}

classdef MovingRegression < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('class_discrimination.MovingRegression');
        popRel = class_discrimination.CDEType('distribution_type="Uncertain" OR distribution_type="Certain"')*ephys.StimTrialGroupAligned;
        shuffles = 100;
        balancing_bins = 20;
    end
    
    methods
        function self = MovingRegression(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            % Compute the class tuning for this cell
            tuple = key;
            
            [cue_class selected_class posterior spikes orientation] = ...
                fetchn(class_discrimination.ClassDiscriminationTrial(key) * ephys.SpikesAligned(key),...
                'stimulus_class', 'selected_class', 'posterior_a', 'spikes_aligned', 'orientation');
            
            cueA = cellfun(@(x) x=='A', cue_class) - 0.5;
            selectedA = cellfun(@(x) x=='A', selected_class);
            A_orientation = ~(orientation > 90 & orientation < 270);
            
            tbins = [-300:100:1500];
            tuple.time_bins = (tbins(1:end-1) + tbins(2:end)) / 2;
            
            if mean(orientation) > 180
                % The certain experiment is from 180 to 360
                orientation = 360 - orientation;
            end

            
            A_o = orientation(selectedA & A_orientation);
            B_o = orientation(~selectedA & ~A_orientation);
            bins = linspace(0, 180.01, class_discrimination.MovingRegression.balancing_bins+1);

            % Equal number of trials from each of the bins
            A_idx = [];
            n = histc(A_o, bins);
            n(end) = [];            
            tuple.a_samples = min(n(1:class_discrimination.MovingRegression.balancing_bins/2));
            for i = 1:10
                ori_idx = find((A_o >= bins(i)) & A_o < bins(i+1));
                ori_idx = ori_idx(randperm(length(ori_idx)));
                ori_idx(tuple.a_samples+1:end) = [];
                A_idx = [A_idx; ori_idx];
            end
            A_o = A_o(A_idx);
            A_o = (A_o - mean(A_o)) / range(A_o);            

            B_idx = [];
            n = histc(B_o, bins);
            n(end) = [];            
            tuple.b_samples = min(n(class_discrimination.MovingRegression.balancing_bins/2+1:end));
            for i = 1:10
                ori_idx = find((B_o >= bins(i+10)) & B_o < bins(i+11));
                ori_idx = ori_idx(randperm(length(ori_idx)));
                ori_idx(tuple.b_samples+1:end) = [];
                B_idx = [B_idx; ori_idx];
            end
            B_o = B_o(B_idx);
            B_o = (B_o - mean(B_o)) / range(B_o);

            for i = 1:length(tbins)-1
                A_count = cellfun(@(x) sum(x >= tbins(i) & x <= tbins(i+1)), spikes(selectedA & A_orientation));
                B_count = cellfun(@(x) sum(x >= tbins(i) & x <= tbins(i+1)), spikes(~selectedA & ~A_orientation));
                
                A_count = A_count(A_idx);
                B_count = B_count(B_idx);
                
                if sum(A_count) == 0 || sum(B_count) == 0
                    return;
                end
                

                stats = regstats(A_count,A_o,'linear',{'beta','rsquare','tstat','fstat'});            
                tuple.modulation_a(i) = stats.beta(2);
                tuple.rsquared_a(i) = stats.rsquare;

                stats = regstats(B_count,B_o,'linear',{'beta','rsquare','tstat','fstat'});            
                tuple.modulation_b(i) = stats.beta(2);
                tuple.rsquared_b(i) = stats.rsquare;
                
                null_a_modulation = zeros(1,class_discrimination.MovingRegression.shuffles);
                null_b_modulation = zeros(1,class_discrimination.MovingRegression.shuffles);                
                null_a_rsquare = zeros(1,class_discrimination.MovingRegression.shuffles);
                null_b_rsquare = zeros(1,class_discrimination.MovingRegression.shuffles);
                
                for j = 1:class_discrimination.MovingRegression.shuffles
                    idx = 1+floor(rand(length(A_o),1)*length(A_o));
                    stats = regstats(A_count(idx),A_o(idx),'linear',{'beta','rsquare','tstat','fstat'});
                    null_a_modulation = stats.beta(2);
                    null_a_rsquare = stats.rsquare;
                    
                    idx = 1+floor(rand(length(B_o),1)*length(B_o));
                    stats = regstats(B_count(idx),B_o(idx),'linear',{'beta','rsquare','tstat','fstat'});
                    null_b_modulation = stats.beta(2);
                    null_b_rsquare = stats.rsquare;
                end
                
                tuple.null_modulation_a(i) = mean(null_a_modulation);
                tuple.null_rsquared_a(i) = mean(null_a_rsquare);
                tuple.null_modulation_b(i) = mean(null_b_modulation);
                tuple.null_rsquared_b(i) = mean(null_b_rsquare);
            end

            insert(this,tuple);
        end
        
        
        function [rsquare] = plotMean (this)
            mr = fetch(this, '*');
            
            dat = [cat(1,mr.rsquared_a); cat(1,mr.rsquared_b)];
            rsquare = abs(dat);
            sem = nanstd(dat,[],1) / sqrt(size(dat,1));
            null = abs([cat(1,mr.null_rsquared_a); cat(1,mr.null_rsquared_b)]);
            rsquare = errorbar(mr(1).time_bins, nanmean(rsquare,1),sem); %,mr(1).time_bins,nanmean(null,1));
            
        end
    end
end
