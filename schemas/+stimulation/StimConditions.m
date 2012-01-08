%{
stimulation.StimConditions (imported) # Handle for trials of a particular condition

-> stimulation.StimTrialGroup
condition_num   : int unsigned          # Condition number
---
condition_info=null         : longblob                      # Matlab structure with information on this condition
stimconditions_ts=CURRENT_TIMESTAMP: timestamp              # automatic timestamp. Do not edit
%}

classdef StimConditions < dj.Relvar
    properties(Constant)
        table = dj.Table('stimulation.StimConditions');
    end
    
    methods 
        function self = StimConditions(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key, stim )
            % Called once of each stimulation
            %   Create the conditions entry for each type
            %   Call makeTuples on StimValidTrials
            %     This will create all the events for that trial
            
            tuple = key;
            
            for cond = 1:length(stim.params.conditions)
                tuple.condition_num = cond; % Condition number
                tuple.condition_info = stim.params.conditions(cond);
                
                insert(this,tuple);
            end
        end
    end
end
