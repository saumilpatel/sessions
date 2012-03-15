%{
sort.VariationalClusteringSU (computed) # Links a spikes to the variational clustering

-> sort.VariationalClusteringAutomatic
cluster_number        : int unsigned               # The cluster number for this unit
---
snr                   : double                     # SNR for this cluster
fp                    : double                     # FP for this cluster
fn                    : double                     # FN for this cluster
mean_waveform=null    : LONGBLOB                   # Spike waveforms
variationalclusteringsu_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef VariationalClusteringSU < dj.Relvar
    properties(Constant)
        table = dj.Table('sort.VariationalClusteringSU');
        
        % Criterion for SU
        min_snr = 4;
        max_fp = 0.1;
        max_fn = 0.1;
        min_spikes = 1000;
    end
    
    methods
        function self = VariationalSU(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(this, key)
            % Process the output of a clustering and determine how many
            % isolated clusters there are
            
            % 1. Get the clusters
            vc = fetch(sort.VariationalClusteringAutomatic(key), '*');
            
            model = vc.model;
            model.Model = MOS(model.Model);
            model.Model = uncompress(model.Model, model);
            model.Waveforms = getWaveforms(sort.VariationalClusteringAutomatic(key));
            
            [fp, fn, snr, ~] = Clustering.getStats(model);
            
            % 2. Screen clsuters as possible SU
            su = find(snr > sort.VariationalClusteringSU.min_snr & ...
                fp < sort.VariationalClusteringSU.max_fp & ...
                fn < sort.VariationalClusteringSU.max_fn & ...
                cellfun(@length, model.ClusterAssignment.data) > sort.VariationalClusteringSU.min_spikes);
            
            for j = 1:length(su)
                tuple = key;
                
                % 3. Insert a cluster element
                tuple.cluster_number = su(j);
                %tuple.spike_times = model.SpikeTimes.data(model.ClusterAssignment.data{su(j)});
                tuple.mean_waveform = cellfun(@(x) mean(x,2), ...
                    model.Waveforms.data, 'UniformOutput', false);
                tuple.snr = snr(su(j));
                tuple.fp = fp(su(j));
                tuple.fn = fn(su(j));
                tuple.electrode_num = vc.electrode_num;
                insert(sort.VariationalClusteringSU, tuple);                
            end
        end

        function [spikeTimes, waveform, spikeFile] = getSpikes(self)
            assert(count(self) == 1, 'Relvar must be scalar!');
            
            cluster_number = fetch1(self,'cluster_number');
            vc = fetch(sort.VariationalClusteringAutomatic & self, 'model');
            
            model = vc.model;
            model.Waveforms = getWaveforms(sort.VariationalClusteringAutomatic & self);
            
            spikeTimes = model.SpikeTimes.data(model.ClusterAssignment.data{cluster_number});
            waveform = fetch1(self,'mean_waveform');
            spikeFile = fetch1(detect.Electrodes * self, 'detect_electrode_file');
        end

        function plot( this )
            assert(count(this) == 1, 'Only can show one cluster');
            vsu = fetch(this, '*');
            vc = fetch(clustering.VariationalClustering(vsu),'*');
            su = fetch(ephys.SingleUnit(vsu),'*');
            data = vc.model.Features.data;
            spikes = vc.model.ClusterAssignment.data{su.cluster_number};
            other = setdiff(1:size(data,1), spikes);
            subplot(121)
            quickProject(data(spikes,:),data(other,:));
            spikes = spikes(1:10:end);
            other = other(1:50:end);
            xlabel('Projection');
            ylabel('Count');
            subplot(122)
            plot3(data(other,1),data(other,2),data(other,3),'.',data(spikes,1),data(spikes,2),data(spikes,3),'.','MarkerSize',3)
            xlabel('Feature 1'); ylabel('Feature 2'); zlabel('Feature 3');
            %subplot(133);
            %wf = getWaveforms(clustering.VariationalClustering(vsu));
            %plot(1:40,wf.data{1}(:,spikes))
        end
    end
end
