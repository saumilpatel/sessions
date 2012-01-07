%{
class_discrimination.TuningCurveParams (lookup) # Properties for computing tuning curves

bins                    : tinyint   # Number of pins for both orientation and posterior
---
%}

classdef TuningCurveParams < dj.Relvar
    properties(Constant)
        table = dj.Table('class_discrimination.TuningCurveParams');
        popRel = class_discrimination.ClassDiscriminationExperiment*ephys.StimTrialGroupAligned*class_discrimination.PeriodAnalysis;
    end
    
    methods
        function self = TuningCurveParams(varargin)
            self.restrict(varargin{:})
        end
        
    end
end