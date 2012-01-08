%{
stimulation.StimTrials (imported) # Information about the valid trials

-> stimulation.StimTrialGroup
trial_num       : int unsigned          # Trial number
---
start_time=0                : bigint unsigned               # Time trial trial started (in ms relative to session start)
end_time=0                  : bigint unsigned               # Time trial trial ended (in ms relative to session start)
trial_params=null           : longblob                      # Stimulation structure for all params
valid_trial                 : boolean                       # If trial is valid or invalid
stimvalidtrials_ts=CURRENT_TIMESTAMP: timestamp             # automatic timestamp. Do not edit
%}

classdef StimTrials < dj.Relvar
    properties(Constant)
        table = dj.Table('stimulation.StimTrials');
    end
    
    methods 
        function self = StimTrials(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key, stim )
            % Create an entry for every valid trial with the condition number and start
            % and end times.  Then create entries for all the events.
            %
            % JC 2011-09-17
            
            tuple = key;
            
            for i = 1:length(stim.params.trials);
                tuple.trial_num = i;
                tuple.valid_trial = stim.params.trials(i).validTrial;
                tuple.start_time = min(stim.events(i).times); % Time trial trial started (in ms)
                tuple.end_time = max(stim.events(i).times); % Time trial trial ended (in ms)
                tuple.trial_params = stim.params.trials(i); % Stimulation structure for all params
                
                insert(this,tuple);
                events = stim.events(i);
                events.types = arrayfun(@(x) stim.eventTypes(x), events.types);
                
                child = key;
                child.trial_num = tuple.trial_num;
                makeTuples(stimulation.StimTrialEvents, child, events);
            end
        end
    end
end
