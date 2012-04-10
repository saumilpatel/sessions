
%{
class_discrimination.ClassificationPreference (computed) # Contains information relavent for behavior classification

-> class_discrimination.ClassDiscriminationExperiment
-> ephys.SpikesAligned
---
class_preference_visual     : enum('A','B')                 # The preference for the visual class
class_preference_visual_sig : double                        # Significance
%}

classdef ClassificationPreference < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('class_discrimination.ClassificationPreference');
        popRel = (class_discrimination.ClassDiscriminationExperiment*ephys.SpikesAligned);
    end
    
    methods
        function self = ClassificationPreference(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)
        function makeTuples( this, key )
            % Compute the class tuning for this cell
            tuple = key;
            
            saA = fetchn(ephys.SpikesAlignedTrial(key).*class_discrimination.ClassDiscriminationTrial('selected_class="A" AND (ABS(orientation) < 10 OR ABS(orientation-360) < 10)'), ...
                'spikes_aligned');
            saB = fetchn(ephys.SpikesAlignedTrial(key).*class_discrimination.ClassDiscriminationTrial('selected_class="B" AND ABS(orientation-180) < 10'), ...
                'spikes_aligned');
            
            countA = cellfun(@(x) sum(x > 150 & x < 1000), saA);
            countB = cellfun(@(x) sum(x > 150 & x < 1000), saB);
            
            if mean(countA) > mean(countB)
                tuple.class_preference_visual = 'A';
            else
                tuple.class_preference_visual = 'B';
            end
            
            tuple.class_preference_visual_sig = ranksum(countA,countB);
            if isnan(tuple.class_preference_visual_sig)
                tuple.class_preference_visual_sig = 1;
            end
            
            
            insert(this,tuple);
        end
        
    end
end
