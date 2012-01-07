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
        
        function makeTuplesMultiUnit( this, key )
            % Import all the spike files for a give cluster set
            %
            % JC 2011-09-15
            
            de = fetch(ephys.DetectionElectrode(key), 'detection_electrode_filename');
            single_unit = false;
            
            disp(sprintf('Found %d spike files to import\n', length(de)));
            
            spike_id = 0;
            for i = 1:length(de)
                tuple = key;
                
                % Get spike file
                fn = getLocalPath(de(i).detection_electrode_filename);
                
                disp(sprintf('Importing spikes from %s',fn));
                
                tt = ah_readTetData(fn);
                tuple.spike_file_path = de(i).detection_electrode_filename;
                tuple.electrode_num = i;
                
                tuple.spike_id = i;      % The spike data
                tuple.spike_times = tt.t;      % The spike data
                tuple.spike_waveforms = cellfun(@(x) mean(x,2), tt.w, 'UniformOutput', false);  % the waveforms
                insert(this,tuple);
            end
        end
        
        function makeTuplesUtah( this, key )
            % Import all the spike files for a give cluster set
            %
            % JC 2011-09-15
            
            % Gets key to SlusterSet/SpikesSet
                 
            % Get the children but don't insert yet so we can get the count
            vcs = fetch(clustering.VariationalClustering(key));

            spike_id = 1;
            
            % 1. Iterate over electrodes
            for vc = vcs'
                
                % 1. Figure out which clusters are considered SU
                vc_key = vc;
                vc = fetch(clustering.VariationalClustering(vc),'*');

                model = vc.model;
                model.Model = MOS(model.Model);
                model.Model = uncompress(model.Model, model);
                model.Waveforms = getWaveforms(clustering.VariationalClustering(vc_key));
                %model.SpikeTimes = getSpikeTimes(clustering.VariationalClustering(vc_key))
                
                [fp, fn, snr, ~] = Clustering.getStats(model);
            
                su = find(snr > clustering.VariationalSU.min_snr & ...
                    fp < clustering.VariationalSU.max_fp & ...
                    fn < clustering.VariationalSU.max_fn & ...
                    cellfun(@length, model.ClusterAssignment.data) > clustering.VariationalSU.min_spikes);
            
                for j = 1:length(su)
                    tuple = key;
                    
                    % 2. Insert a spike element
                    tuple.spike_id = spike_id;
                    tuple.spike_times = model.SpikeTimes.data(model.ClusterAssignment.data{su(j)});
                    tuple.spike_waveforms = cellfun(@(x) mean(x,2), ...
                        model.Waveforms.data, 'UniformOutput', false);
                    tuple.spike_file_path = fetch1(ephys.DetectionElectrode( ...
                        setfield(tuple,'electrode_number',vc.electrode_number)), ...
                        'detection_electrode_filename');
                    tuple.electrode_num = vc.electrode_number;
                    insert(ephys.Spikes, tuple);
                    
                    % 3. Insert the SU information
                    tuple = key;
                    tuple.spike_id = spike_id;
                    tuple.cluster_number = su(j);
                    tuple.snr = snr(su(j));
                    tuple.fp = fp(su(j));
                    tuple.fn = fn(su(j));
                    insert(ephys.SingleUnit, tuple);
                    
                    % 4. Link the SU to the VariationalClustering\
                    tuple = key;
                    tuple.spike_id = spike_id;
                    tuple.electrode_number = vc.electrode_number;
                    insert(clustering.VariationalSU, tuple);
                    
                    spike_id = spike_id + 1;
                end 
            end
        end
    end
end
