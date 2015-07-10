%{
sort.BPAutomatic (computed) # Binary Pursuit sorting - automatic step

-> sort.Sets
---
model                       : longblob                      # The fitted model
git_hash=""                 : varchar(40)                   # git hash of bpsort package
bpautomatic_ts=CURRENT_TIMESTAMP: timestamp             # automatic timestamp. Do not edit
%}

classdef BPAutomatic < dj.Relvar & dj.AutoPopulate

    properties(Constant)
        popRel = sort.Sets & (detect.Sets & (sort.SetsCompleted * sort.Methods & 'sort_method_name = "MoKsm"'))
    end

    methods (Access = protected)
        function makeTuples(self, key)
            
            tuple = key;
            
            % get spike times from initial MoKsm models
            initKey = key;
            initKey.sort_method_num = fetch1(sort.Methods & 'sort_method_name = "MoKsm"', 'sort_method_num');
            [count, stride] = fetch1(detect.ChannelGroupParams * acq.EphysTypes * acq.Ephys & initKey, 'count', 'stride');
            n = max(fetchn(detect.ChannelGroups & (acq.EphysTypes * acq.Ephys & initKey), 'electrode_num'));
            spikeTimes = {};
            modelKeys = fetch(sort.KalmanFinalize & initKey);
            for i = 1 : numel(modelKeys)
                model = fetch1(sort.KalmanFinalize & modelKeys(i), 'final_model');
                model = uncompress(MoKsmInterface(model));
                for cluster = model.getClusterIds()
                    spikes = model.getSpikesByClusIds(cluster);
                    w = cellfun(@(x) median(x(:, spikes), 2), model.Waveforms.data, 'uni', false);
                    w = [w{:}];
                    [~, peak] = max(max(w) - min(w));
                    if peak > stride || modelKeys(i).electrode_num == 1 && ...
                            peak <= count - stride || modelKeys(i).electrode_num == n
                        spikeTimes{end + 1} = model.SpikeTimes.data(spikes); %#ok
                    end
                end
            end
            
            
            self.insert(tuple);
        end
    end
end
