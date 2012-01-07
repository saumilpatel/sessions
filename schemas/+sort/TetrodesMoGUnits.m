%{
sort.TetrodesMoGUnits (imported) # single units for MoG clustering

->sort.TetrodesMoGFinalize
---
%}

classdef TetrodesMoGUnits < dj.Relvar
    properties(Constant)
        table = dj.Table('sort.TetrodesMoGFinalize');
    end
    
    methods 
        function self = TetrodesMoGUnits(varargin)
            self.restrict(varargin{:})
        end
        
        function [spikeTimes, waveform, spikeFile] = getSpikes(self)
            assert(count(self) == 1, 'Relvar must be scalar!');
            spikeFile = fetch1(detect.Electrodes * self, 'detect_electrode_file');
            sortFile = fetch1(sort.TetrodesMoGFinalize * self, 'final_sort_file');
            results = load(getLocalPath(sortFile));
            unitNum = fetch1(self, 'unit_num');
            H = clus_clusterByMOGResult(results.job.X, results.mogLL.covMat(:,:,unitNum), ...
                results.mogLL.Mu(unitNum,:), results.mogLL.Pi(unitNum));
            [~, assignment] = max(H, [], 2);
            tt = ah_readTetData(getLocalPath(spikeFile), 'index', find(assignment == unitNum));
            waveform = cell2mat(cellfun(@(x) mean(x, 2), tt.w));
            spikeTimes = tt.t;
        end        
    end
end
