
%{
class_discrimination.TrialTypes (computed) # Contains information relavent for behavior classification

trial_type        : int unsigned      # ID of the trial type
---
orientation_bin   : float             # Center of the orientation bin
decision          : enum('A','B')     # Whether the animal selected A or B
%}

classdef TrialTypes < dj.Relvar
    properties(Constant)
        table = dj.Table('class_discrimination.TrialTypes');
        orientation_bin_size = 10;
    end
    
    methods 
        function self = TrialTypes(varargin)
            self.restrict(varargin{:})
        end
    end

    methods (Static)
        function trial_type = getTrialType(orientation, decision)
            decision = upper(decision);
            assert(decision == 'A' || decision == 'B', 'Invalid decision');
            orientation_bin = floor(orientation / class_discrimination.TrialTypes.orientation_bin_size);
            trial_type = orientation_bin * 2 + (decision == 'B');
            if count(class_discrimination.TrialTypes(sprintf('trial_type=%d',trial_type))) == 0
                tuple = struct('trial_type',trial_type, ...
                    'decision', decision, ...
                    'orientation_bin', orientation_bin + class_discrimination.TrialTypes.orientation_bin_size / 2);
                insert(class_discrimination.TrialTypes, tuple);
            end
        end
    end
end