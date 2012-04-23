
%{
class_discrimination.ClassificationNeuron (computed) # Contains information relavent for behavior classification

-> class_discrimination.ClassDiscriminationExperiment
-> ephys.SpikesAligned
---
class_preference_visual     : enum('A','B')                 # The preference for the visual class
class_preference_visual_sig : double                        # Significance
%}

classdef ClassificationNeuron < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('class_discrimination.ClassificationNeuron');
        popRel = (class_discrimination.ClassDiscriminationExperiment*ephys.SpikesAligned);
    end
    
    methods
        function self = ClassificationNeuron(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)
        function makeTuples( this, key )
            % Compute the class tuning for this cell
            tuple = key;
            
            saA = fetchn(ephys.SpikesAlignedTrial(key).*class_discrimination.ClassDiscriminationTrial('selected_class="A"'), ...
                'spikes_aligned');
            saB = fetchn(ephys.SpikesAlignedTrial(key).*class_discrimination.ClassDiscriminationTrial('selected_class="B"'), ...
                'spikes_aligned');
            
            countA = cellfun(@(x) sum(x > 0 & x < 500), saA);
            countB = cellfun(@(x) sum(x > 0 & x < 500), saB);
            
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
