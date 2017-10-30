%{
ephys.SpikesAlignedTrial (computed) # Spikes aligned to an event

-> ephys.SpikesAligned
-> stimulation.StimTrials
---
spikes_aligned=null         : longblob                      # Set of trial spikes
spikesalignedtrial_ts=CURRENT_TIMESTAMP: timestamp               # automatic timestamp. Do not edit
%}

classdef SpikesAlignedTrial < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.SpikesAlignedTrial');
    end
    
    methods 
        function self = SpikesAlignedTrial(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            % Import all the aligned spikes for the trials for this key
            
            trials = fetch(stimulation.StimTrials(key,'valid_trial=TRUE'));
            spikes = fetch1(ephys.Spikes(key),'spike_times');

            key.spikes_aligned = [];
            tuples = dj.struct.join(key,trials);
            
            for tuple = tuples'
                alignTime = fetchn(stimulation.StimTrialEvents(tuple),'event_time');
                try
                    endTime = fetch1(stimulation.StimTrialEvents(setfield(tuple,'event_type','endStimulus')),'event_time');
                catch
                    
                    ev_times = fetchn(stimulation.StimTrialEvents(setfield(tuple,'event_type','showSubStimulus')),'event_time');
                    endTime = max(ev_times) + 60;
                end
                    
                
                tuple.spikes_aligned = spikes(spikes > (alignTime - tuple.pre_stim_time) & ...
                    (spikes < (endTime + tuple.post_stim_time))) - double(alignTime);
                
                insert(this,tuple);
            end
        end
    end
end
