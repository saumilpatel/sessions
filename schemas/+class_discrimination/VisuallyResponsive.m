
%{
class_discrimination.VisuallyResponsive (computed) # Contains information relavent for behavior classification

-> class_discrimination.ClassDiscriminationExperiment
-> ephys.SpikesAligned
---
sig : double                        # Significance
%}

classdef VisuallyResponsive < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('class_discrimination.VisuallyResponsive');
        popRel = (class_discrimination.ClassDiscriminationExperiment*ephys.SpikesAligned);
    end
    
    methods
        function self = VisuallyResponsive(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)
        function makeTuples( this, key )
            % Compute the class tuning for this cell
            tuple = key;
            
            counts = fetchn(ephys.SpikesAlignedTrial(key).*class_discrimination.ClassDiscriminationTrial, ...
                'spikes_aligned');

            count_pre = cellfun(@(x) sum(x > -300 & x < 150), counts);
            count_post = cellfun(@(x) sum(x > 150 & x < 600), counts);

            tuple.sig = ranksum(count_pre,count_post);
            if isnan(tuple.sig)
                tuple.sig = 1;
            end

            insert(this,tuple);
        end
        
    end
end
