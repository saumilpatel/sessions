%{
ephys.SpikesBinned (computed) # Settings for computing the PSTH

-> ephys.StimTrialGroupBinned
-> stimulation.StimValidTrials
---
spikes_binned=null          : longblob                      # Binned vector of spikes
spikesbinned_ts=CURRENT_TIMESTAMP: timestamp                # automatic timestamp. Do not edit
%}

classdef SpikesBinned < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.SpikesBinned');
    end
    
    methods 
        function self = SpikesBinned(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            % Import all the binned spikes for the trials for this key
            
            trials = fetch(stimulation.StimValidTrials(key));
            spikes = fetch1(ephys.Spikes(key),'spike_times');
            
            key.spikes_binned = [];
            tuples = dj.utils.structJoin(key,trials);
            
            for tuple = tuples'
                alignTime = fetchn(stimulation.StimTrialEvents(tuple),'event_time');
                endTime = fetch1(stimulation.StimTrialEvents(setfield(tuple,'event_type','endStimulus')),'event_time');
                these_times = spikes(spikes > (alignTime - tuple.pre_stim_time) & ...
                    (spikes < (endTime + tuple.post_stim_time))) - alignTime;
                
                tuple.spikes_binned = uint8(histc(these_times, -tuple.pre_stim_time:tuple.bin_width:(endTime-alignTime+tuple.post_stim_time)));
                
                insert(this,tuple);
            end
        end
        
        function [psth times] = psth(sb)
            % Compute and return the PSTH
            bin_width = unique(fetchn(sb,'bin_width'));
            assert(length(bin_width) == 1, 'Only can be called for one bin width');
            pre_stim_time = unique(fetchn(sb,'pre_stim_time'));
            assert(length(pre_stim_time) == 1, 'Only for one pre stim time');
            
            dat = fetchn(sb,'spikes_binned');
            l = min(cellfun(@length, dat));
            dat = cellfun(@(x) reshape(x(1:l),[],1), dat, 'UniformOutput', false);
            dat = cat(2,dat{:});
            
            psth = mean(dat,2) * 1000 / bin_width;
            times = -pre_stim_time + (0:bin_width:(l-1)*bin_width);
            
            if nargout == 0
                plot(times,psth)
            end
        end
        
    end
end
