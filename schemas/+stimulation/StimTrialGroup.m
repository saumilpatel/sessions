%{
stimulation.StimTrialGroup (imported) # Set of imported trials

-> sessions.Stimulation
---
stim_constants                     : longblob               # A structure with all the stimulation constants
stimtrialgroup_ts=CURRENT_TIMESTAMP: timestamp              # automatic timestamp. Do not edit
%}
classdef StimTrialGroup < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('stimulation.StimTrialGroup');
        popRel = sessions.Stimulation('(correct_trials + incorrect_trials) > 400')  .* sessions.Ephys;
    end
    
    methods 
        function self = StimTrialGroup(varargin)
            self.restrict(varargin{:})
        end
        
        function self = makeTuples(self, key)
            tuple = key;
            
            try
                [fn stim] = getStimFile(sessions.Stimulation(key),'Synced');
            catch
                [fn stim] = getStimFile(sessions.Stimulation(key),'Synched');
            end
            tuple.stim_constants = stim.params.constants;
            insert(self, tuple);

            % Insert conditions
            makeTuples(stimulation.StimConditions, key, stim);
            % Insert trials
            makeTuples(stimulation.StimTrials, key, stim);

        end
    end
end
