
%{
class_discrimination.CDEType (computed) # Contains information relavent for behavior classification

-> class_discrimination.ClassDiscriminationExperiment
---
distribution_type : enum('Unclassified','Uncertain','Certain','WeiJi') # Type of distributions used
cdetype_ts=CURRENT_TIMESTAMP: timestamp# automatic timestamp. Do not edit
%}

classdef CDEType < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('class_discrimination.CDEType');
        popRel = class_discrimination.ClassDiscriminationExperiment
    end
    
    methods 
        function self = CDEType(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)        
        function makeTuples( this, key )
            % Get additional information for each trial
            tuple = key;
            
            cde = fetch(class_discrimination.ClassDiscriminationExperiment(key), '*');
            
            tuple.distribution_type = 'Unclassified';
            
            if (cde.range_a > 110 && cde.range_b > 110 && cde.distribution_entropy > 0.2)
                tuple.distribution_type = 'Uncertain';
            elseif (round(cde.range_a) == 90 && round(cde.range_b) == 90 && cde.distribution_entropy < 1e-3)
                tuple.distribution_type = 'Certain';
            end
            
            insert(this,tuple);
        end
        
    end
end