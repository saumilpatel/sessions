
%{
class_discrimination.PeriodAnalysis (lookup) # Contains information relavent for behavior classification

regression_time_period     : enum('Cue','Memory')                 # The time period to use
regression_time_latency    : double                        # Neural latency to use
---
%}

classdef PeriodAnalysis < dj.Relvar
    properties(Constant)
        table = dj.Table('class_discrimination.PeriodAnalysis');
    end
    
    methods
        function self = PeriodAnalysis(varargin)
            self.restrict(varargin{:})
        end
        
    end
end