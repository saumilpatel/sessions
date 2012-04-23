
%{
class_discrimination.TaskResponse (computed) # Contains information relavent for behavior classification

-> class_discrimination.ClassDiscriminationExperiment
-> ephys.SpikesAligned
---
significance            : double           # Significance of difference between epochs
%}

classdef TaskResponse < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('class_discrimination.TaskResponse');
        popRel = (class_discrimination.ClassDiscriminationExperiment*ephys.SpikesAligned);
    end
    
    methods
        function self = TaskResponse(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)        
        function makeTuples( this, key )
            % Compute the class tuning for this cell
            tuple = key;
            
            [sa] = fetchn(ephys.SpikesAlignedTrial(key),'spikes_aligned');
            
            params = {'display','off','continuous',[]};
            
            % Compute for visual period
            fixation = cellfun(@(x) sum(x > 0 & x < 300) / 0.3, sa);
            visual = cellfun(@(x) sum(x > 0 & x < 500) / 0.5, sa);
            
            p = ranksum(fixation,visual);
            tuple.significance = p;

            if isnan(p)
                return;
            end
            
            insert(this,tuple);
        end
        
    end
end
