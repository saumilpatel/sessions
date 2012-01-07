%{
stimulation.StimValidTrials (imported) # Information about the valid trials

-> stimulation.StimConditions
trial_num       : int unsigned          # Trial number
---
start_time=0                : bigint unsigned               # Time trial trial started (in ms relative to session start)
end_time=0                  : bigint unsigned               # Time trial trial ended (in ms relative to session start)
trial_params=null           : longblob                      # Stimulation structure for all params
stimvalidtrials_ts=CURRENT_TIMESTAMP: timestamp             # automatic timestamp. Do not edit
%}

classdef StimValidTrials < dj.Relvar
    properties(Constant)
        table = dj.Table('stimulation.StimValidTrials');
    end
    
    methods 
        function self = StimValidTrials(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key, stim )
            % Create an entry for every valid trial with the condition number and start
            % and end times.  Then create entries for all the events.
            %
            % JC 2011-09-17
            
            tuple = key;
            
            idx = find([stim.params.trials.validTrial] ~= 0);
            for i = idx
                tuple.trial_num = i;
                tuple.condition_num = stim.params.trials(i).condition;
                tuple.start_time = min(stim.events(i).times); % Time trial trial started (in ms)
                tuple.end_time = max(stim.events(i).times); % Time trial trial ended (in ms)
                tuple.trial_params = stim.params.trials(i); % Stimulation structure for all params
                
                insert(this,tuple);
                events = stim.events(i);
                events.types = arrayfun(@(x) stim.eventTypes(x), events.types);
                
                child = key;
                child.condition_num = tuple.condition_num;
                child.trial_num = tuple.trial_num;
                makeTuples(stimulation.StimTrialEvents, child, events);
            end
        end
    end
end
