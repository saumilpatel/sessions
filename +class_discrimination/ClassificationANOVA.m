
%{
class_discrimination.ClassificationANOVA (computed) # Contains information relavent for behavior classification

-> class_discrimination.ClassDiscriminationExperiment
-> ephys.StimTrialGroupAligned
---
visual_class_sig            : double           # Significance across orientation in visual
visual_orientation_sig      : double           # Significance across orientation in visual
earlymemory_class_sig       : double           # Significance across orientation in early memory
earlymemory_orientation_sig : double           # Significance across orientation in early memory
latememory_class_sig        : double           # Significance across orientation in late memory
latememory_orientation_sig  : double           # Significance across orientation in late memory
epoch_sig       : double                       # Significance when comparing across epochs
%}

classdef ClassificationANOVA < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('class_discrimination.ClassificationANOVA');
        popRel = (class_discrimination.ClassDiscriminationExperiment*ephys.StimTrialGroupAligned);
    end
    
    methods
        function self = ClassificationANOVA(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            % Compute the class tuning for this cell
            tuple = key;
            
            [selected sa orientation] = fetchn(ephys.SpikesAligned(key) * class_discrimination.ClassDiscriminationTrial, ...
                'selected_class','spikes_aligned','orientation');
            
            % Categorize orientations
            orientation = floor(orientation / 18);
            orientation = orientation - min(orientation);
            
            group = [cellfun(@(x) x=='A', selected) orientation];
            
            params = {'display','off','continuous',[]};
            
            % Compute for visual period
            count = cellfun(@(x) sum(x > 0 & x < 500), sa);
            p = anovan(count, group, params{:});
            
            tuple.visual_class_sig = p(1);
            tuple.visual_orientation_sig = p(2);
            
            % Compute for early memory period
            count = cellfun(@(x) sum(x > 500 & x < 1000), sa);
            p = anovan(count, group, params{:});
            
            tuple.earlymemory_class_sig = p(1);
            tuple.earlymemory_orientation_sig = p(2);

            % Compute for late memory period
            count = cellfun(@(x) sum(x > 1000 & x < 1500), sa);
            p = anovan(count, group, params{:});
            
            tuple.latememory_class_sig = p(1);
            tuple.latememory_orientation_sig = p(2);

            epochs =[-300 0; 0 300; 300 600; 600 900; 900 1200; 1200 1500];
            counts = [];
            epoch = [];
            for i = 1:size(epochs,1)
                count = cellfun(@(x) sum(x > epochs(i,1) & x < epochs(i,2)), sa);
                m(i) = mean(count);
                counts = [counts; count];
                epoch = [epoch; i * ones(size(count))];
            end
            
            tuple.epoch_sig = anova1(counts,epoch,'off');            
            
            if(min(m) < 1)
                return;
            end
            
            insert(this,tuple);
        end
        
    end
end
