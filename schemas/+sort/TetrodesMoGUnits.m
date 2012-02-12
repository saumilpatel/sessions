%{
sort.TetrodesMoGUnits (imported) # single units for MoG clustering

->sort.TetrodesMoGFinalize
cluster_number : tinyint unsigned # unit number on this electrode
---
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
            clusterNum = fetch1(self, 'cluster_number');
            tt = ah_readTetData(getLocalPath(spikeFile), 'index', find(clustering.cluBySpike == clusterNum));
            waveform = cellfun(@(x) mean(x, 2), tt.w, 'UniformOutput', false);
            waveform = [waveform{:}];
            spikeTimes = tt.t;
        end        
    end
end
