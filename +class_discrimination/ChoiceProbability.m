%{
class_discrimination.ChoiceProbability (computed) # Multiple variable regression for decision and posterior

-> class_discrimination.ClassDiscriminationExperiment
-> ephys.StimTrialGroupAligned
---
time_bins=null              : longblob     # Time bins for the regression
modulation_decision=null    : longblob     # Spikes difference over time
modulation_null=null        : longblob     # The shuffled CP
visual_cp=null              : double       # Average choice probability in visual period
%}

classdef ChoiceProbability < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('class_discrimination.ChoiceProbability');
        popRel = class_discrimination.CDEType('distribution_type="Uncertain" OR distribution_type="Certain"')*ephys.StimTrialGroupAligned;
        shuffles = 100;
    end
    
    methods
        function self = ChoiceProbability(varargin)
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
            
            tbins = [-300:100:1500];
            tuple.time_bins = (tbins(1:end-1) + tbins(2:end)) / 2;
            
            if mean(orientation) > 180
                % The certain experiment is from 180 to 360
                orientation = 360 - orientation;
            end

            orientation = 1 + floor(orientation / 18);
            orientation(orientation == 11) = 10;

            for i = 1:length(tbins)-1
                count = cellfun(@(x) sum(x >= tbins(i) & x <= tbins(i+1)), spikes);
                
                for j = 1:10
                    idxA = find(selectedA & orientation == j);
                    idxB = find(~selectedA & orientation == j);
                    
                    if length(idxA) < 10 || length(idxB) < 10
                        cp(j) = nan;
                        cp_shuffled(j) = nan;
                        break;
                    end
                    
                    [tp fp] = roc(count(idxA), count(idxB));
                    cp(j) = auc(tp,fp);
                    
                    for k = 1:length(class_discrimination.ChoiceProbability.shuffles)
                        count_shuffled = count(randperm(length(count)));
                        [tp fp] = roc(count_shuffled(idxA), count_shuffled(idxB));
                        shuf(k) = auc(tp,fp);
                    end
                    cp_shuffled(j) = mean(shuf);

                end
                if sum(isnan(cp)) > 3
                    disp('Not enough trials');
                    return;
                end
                tuple.modulation_decision(i) = nanmean(cp);
                tuple.modulation_null(i) = nanmean(cp_shuffled);
            end
            
            tuple.visual_cp = mean(tuple.modulation_decision(tbins(1:end-1) > 0 & tbins(2:end) <= 500));        

            insert(this,tuple);
        end
        
        
        function [rsquare null] = plotMean (this)
            mr = fetch(this, '*');
            
            dat = abs(cat(1,mr.modulation_decision) - 0.5);
            sem = nanstd(dat,[],1) / sqrt(size(dat,1));
            
            null = abs(cat(1,mr.modulation_null) - 0.5);
            sem_null = nanstd(null, [], 1) / sqrt(size(null,1));
            cla; hold on
            rsquare = errorbar(mr(1).time_bins, nanmean(dat,1),sem);
            null = errorbar(mr(1).time_bins, nanmean(null,1), sem_null);
            
        end
    end
end
