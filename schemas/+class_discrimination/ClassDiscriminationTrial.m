
%{
class_discrimination.ClassDiscriminationTrial (computed) # Contains information relavent for behavior classification

-> class_discrimination.ClassDiscriminationExperiment
-> stimulation.StimTrials
---
stimulus_class              : enum('A','B')                 # The stimulus class (A or B)
selected_class              : enum('A','B')                 # The selected stimulus class (A or B)
correct_response            : tinyint                       # True for a correct response
correct_direction           : enum('Left','Right')          # Direction for correct answer
selected_direction          : enum('Left','Right')          # Direction for correct answer
orientation                 : float                         # Orientation of the grating
posterior_a                 : float                         # Posterior probability of A
classdiscriminationtrial_ts=CURRENT_TIMESTAMP: timestamp    # automatic timestamp. Do not edit
%}

classdef ClassDiscriminationTrial < dj.Relvar
    properties(Constant)
        table = dj.Table('class_discrimination.ClassDiscriminationTrial');
    end
    
    methods 
        function self = ClassDiscriminationTrial(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            tuple = key;
            
            constants = fetch1(stimulation.StimTrialGroup(key),'stim_constants');
            params = fetch1(stimulation.StimTrials(key),'trial_params');
            condition = fetch1(stimulation.StimConditions(key,sprintf('condition_num=%d',params.condition)),'condition_info');
            
            assert(fetch1(stimulation.StimTrials(key),'valid_trial') == 1, 'Only import valid trials');
            
            %% Determine cue class
            % cueClass 1: cue B
            % cueClass 2: cue A
            var = [condition.cueClass params.correctResponse];
            if isequal(var, [1 0])
                tuple.stimulus_class = 'B';
                tuple.selected_class = 'A';
            elseif isequal(var, [2 0])
                tuple.stimulus_class = 'A';
                tuple.selected_class = 'B';
            elseif isequal(var, [1 1])
                tuple.stimulus_class = 'B';
                tuple.selected_class = 'B';
            elseif isequal(var, [2 1])
                tuple.stimulus_class = 'A';
                tuple.selected_class = 'A';
            else
                error('The cueClass has an invalid value');
            end
            
            %% Determine response direction
            % targetSetup 1: left target is B
            % targetSetup 2: left target is A
            % if cueClass is targetSetup then correct response on left
            var = [(condition.cueClass == condition.targetSetup) params.correctResponse];
            if isequal(var, [1 0])
                tuple.correct_direction = 'Left';
                tuple.selected_direction = 'Right';
            elseif isequal(var, [0 0])
                tuple.correct_direction = 'Right';
                tuple.selected_direction = 'Left';
            elseif isequal(var, [1 1])
                tuple.correct_direction = 'Left';
                tuple.selected_direction = 'Left';
            elseif isequal(var, [0 1])
                tuple.correct_direction = 'Right';
                tuple.selected_direction = 'Right';
            else
                error('The cueClass has an invalid value');
            end
            
            %% Other things
            tuple.correct_response = params.correctResponse ~= 0;
            tuple.orientation = params.trialDirection; % Orientation of the grating
            
            dA = eval(['@(theta) ' constants.distributionA]);
            dB = eval(['@(theta) ' constants.distributionB]);
            theta = 0:.1:360;
            dA = interp1(theta, dA(theta), tuple.orientation);
            dB = interp1(theta, dB(theta), tuple.orientation);
            tuple.posterior_a = dA ./ (dA + dB);
            
            insert(this,tuple);
        end
    end
end