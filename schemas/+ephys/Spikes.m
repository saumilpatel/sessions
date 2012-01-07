%{
ephys.Spikes (imported) # A spike train from a single or multi unit

-> ephys.SpikeSet
spike_id        : int unsigned          # The spike data
---
electrode_num=0             : int unsigned                  # The electrode number
spike_times=null            : longblob                      # The spike timing data
spike_waveforms=null        : longblob                      # The spike waveform data
spike_file_path=""          : varchar(255)                  # The file containing the spike data
spikes_ts=CURRENT_TIMESTAMP : timestamp                     # automatic timestamp. Do not edit
%}

classdef Spikes < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.Spikes');
    end
    
    methods
        function self = Spikes(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(this, key)
            type = fetch1(sort.SetsCompleted(key) * sort.Methods, 'sort_method_name');
            
            if strcmp(type,'MultiUnit')
                accessor = sort.MultiUnit;
            else
                error('"Unimplemented"');
            end
            
            keys = fetch(accessor & key);
            disp(sprintf('Found %d spike files to import\n', length(keys)));
            for i = 1:length(keys)
                tuple = key;
                tuple.spike_id = i;
                [tuple.spike_times, tuple.spike_waveforms, tuple.spike_file_path] = getSpikes(accessor & keys(i));
                tuple.electrode_num = keys(i).electrode_num;
                
                % TODO: Add switch here which adds additional information in a method specific manner
            end
        end
    end
end
