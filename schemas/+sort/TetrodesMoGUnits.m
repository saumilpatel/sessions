%{
sort.TetrodesMoGUnits (imported) # single units for MoG clustering

-> sort.TetrodesMoGFinalize
cluster_number : tinyint unsigned # unit number on this electrode
---
fp             : double           # estimated false positive rate for this cluster
fn             : double           # estimated false negative rate
snr            : double           # signal-to-noise ratio
mean_waveform  : BLOB             # average waveform
%}

classdef TetrodesMoGUnits < dj.Relvar
    properties(Constant)
        table = dj.Table('sort.TetrodesMoGUnits');
    end
    
    methods 
        function self = TetrodesMoGUnits(varargin)
            self.restrict(varargin{:})
        end
        
        function [spikeTimes, waveform, spikeFile] = getSpikes(self)
            assert(count(self) == 1, 'Relvar must be scalar!');
            spikeFile = fetch1(detect.Electrodes * self, 'detect_electrode_file');
            sortFile = [fetch1(sort.Sets * self, 'sort_set_path') sprintf('/clusteringTT%d.mat', fetch1(self, 'electrode_num'))];
            clustering = getfield(load(getLocalPath(sortFile)), 'clustering'); %#ok
            [clusterNum, waveform] = fetch1(self, 'cluster_number', 'mean_waveform');
            spikeTimes = clustering.spikeTimes{clusterNum};
        end        
    end
end
