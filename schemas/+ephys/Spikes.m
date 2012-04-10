%{
ephys.Spikes (imported) # A spike train from a single or multi unit

-> ephys.SpikeSet
unit_id        : int unsigned          # The spike data
---
electrode_num=0             : int unsigned                  # The electrode number
spike_times=null            : longblob                      # The spike timing data
mean_waveform=null        : longblob                      # The spike waveform data
spike_file_path=""          : varchar(255)                  # The file containing the spike data
%}

classdef Spikes < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.Spikes');
    end
    
    methods
        function self = Spikes(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(~, key)
            type = fetch1(sort.SetsCompleted * sort.Methods & key, 'sort_method_name');
            
            switch type
                case 'MultiUnit'
                    accessor = sort.MultiUnit;
                    link = [];
                case {'VariationalClustering', 'Utah'}
                    accessor = sort.VariationalClusteringSU;
                    link = sort.VariationalClusteringLink;
                case 'TetrodesMoG'
                    accessor = sort.TetrodesMoGUnits;
                    link = sort.TetrodesMoGLink;
                otherwise
                    error('"Unimplemented"');
            end
            
            keys = fetch(accessor & key);
            fprintf('Found %d units to import\n', length(keys));
            for i = 1:length(keys)
                tuple = key;
                tuple.unit_id = i;
                [tuple.spike_times, tuple.mean_waveform, tuple.spike_file_path] = getSpikes(accessor & keys(i));
                tuple.electrode_num = keys(i).electrode_num;
                insert(ephys.Spikes, tuple)
                
                if numel(link)
                    % link to method specific clustering table
                    tuple = key;
                    tuple.unit_id = i;
                    tuple.electrode_num = keys(i).electrode_num;
                    tuple.cluster_number = keys(i).cluster_number;
                    insert(link, tuple);
                
                    % add single units
                    su = fetch(accessor & tuple, 'snr', 'fp', 'fn');
                    tuple.snr = su.snr;
                    tuple.fp = su.fp;
                    tuple.fn = su.fn;
                    tuple = rmfield(tuple, 'electrode_num');
                    insert(ephys.SingleUnit, tuple);
                end
            end
        end
    end
end
