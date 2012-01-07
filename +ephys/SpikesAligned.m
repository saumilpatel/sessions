%{
ephys.SpikesAligned (computed) # Spikes aligned to an event

-> ephys.StimTrialGroupAligned
-> stimulation.StimValidTrials
---
spikes_aligned=null         : longblob                      # Set of trial spikes
spikesaligned_ts=CURRENT_TIMESTAMP: timestamp               # automatic timestamp. Do not edit
%}

classdef SpikesAligned < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.SpikesAligned');
    end
    
    methods 
        function self = SpikesAligned(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            % Import all the aligned spikes for the trials for this key
            
            trials = fetch(stimulation.StimValidTrials(key));
            spikes = fetch1(ephys.Spikes(key),'spike_times');
            
            key.spikes_aligned = [];
            tuples = dj.utils.structJoin(key,trials);
            
            for tuple = tuples'
                alignTime = fetchn(stimulation.StimTrialEvents(tuple),'event_time');
                endTime = fetch1(stimulation.StimTrialEvents(setfield(tuple,'event_type','endStimulus')),'event_time');
                
                tuple.spikes_aligned = spikes(spikes > (alignTime - tuple.pre_stim_time) & ...
                    (spikes < (endTime + tuple.post_stim_time))) - alignTime;
                
                insert(this,tuple);
            end
        end
    end
end
