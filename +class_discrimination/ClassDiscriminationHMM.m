
%{
class_discrimination.ClassDiscriminationHMM (computed) # HMM model for class discrimination experiment

-> ephys.SpikesBinnedSet
-> class_discrimination.ClassDiscriminationExperiment
---
gamma=null                  : longblob                      # 
emiss=null                  : longblob                      # 
trans=null                  : longblob                      # 
pi=null                     : longblob                      # 
ll=null                     : longblob                      # 
classdiscriminationhmm_ts=CURRENT_TIMESTAMP: timestamp      # automatic timestamp. Do not edit
%}

classdef ClassDiscriminationHMM< dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('class_discrimination.ClassDiscriminationHMM');
        popRel = class_discrimination.ClassDiscriminationExperiment*ephys.SpikesBinnedSet;
    end
    
    methods
        function self = ClassDiscriminationHMM(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key )
            tuple = key;
            
            [spike_id trial_num spikes_binned] = fetchn(ephys.SpikesBinned(key),'spike_id', 'trial_num', 'spikes_binned');
            
            spike_ids = sort(unique(spike_id));
            trial_nums = sort(unique(trial_num));
            max_bins = max(cellfun(@length, spikes_binned));
            
            data = nan(length(trial_nums), max_bins, length(spike_ids));
            for i = 1:length(trial_nums)
                for j = 1:length(spike_ids)
                    idx = find(spike_id == spike_ids(j) & trial_num == trial_nums(i));
                    assert(length(idx) == 1, 'Only should be only one element per trial and and cell');
                    data(i,1:length(spikes_binned{idx}),j) = spikes_binned{idx};
                end
            end
            
            rng('default');
            [tuple.gamma tuple.emiss tuple.trans tuple.pi tuple.ll] = hmmPoisson(data);
            rng('shuffle');
            
            insert(this,tuple);
        end
        
    end
end