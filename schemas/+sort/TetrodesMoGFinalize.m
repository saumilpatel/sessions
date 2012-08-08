%{
sort.TetrodesMoGFinalize (imported) # finalize clustering

->sort.TetrodesMoGManual
---
finalize_sort_ts = CURRENT_TIMESTAMP : timestamp    # current timestamps
%}

classdef TetrodesMoGFinalize < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('sort.TetrodesMoGFinalize');
        popRel = sort.TetrodesMoGManual;
    end
    
    methods 
        function self = TetrodesMoGFinalize(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)
        function makeTuples(self, key)
            % do model refit
            sortPath = fetch1(sort.Sets(key), 'sort_set_path');
            resultFile = fullfile(getLocalPath(sortPath), sprintf('resultTT%d.mat', key.electrode_num));
            job = getfield(load(resultFile, 'job'), 'job'); %#ok
            job.status = 2;
            clus_runPostProcessing(job);
            insert(self, key);
            
            % Compute posteriors
            modelFile = fullfile(getLocalPath(sortPath), sprintf('modelTT%d.mat', key.electrode_num));
            model = getfield(load(modelFile), 'model'); %#ok
            nUnits = numel(model.cluster);
            nSpikes = size(job.X, 1);
            p = zeros(nSpikes, nUnits);
            for i = 1:nUnits
                c = model.cluster(i);
                for j = 1:numel(c.prior);
                    p(:,i) = p(:,i) + c.prior(j) * clus_mvn(job.X, c.mean(j,:), c.covMat(:,:,j));
                end
            end
            p = bsxfun(@rdivide, p, sum(p, 2));
            [~, assignment] = max(p, [], 2);
            
            % insert single units into TetrodesMoGUnits
            spikeFile = getLocalPath(fetch1(detect.Electrodes(key), 'detect_electrode_file'));
            for i = 2:nUnits % 1 = MUA
                tuple = key;
                tuple.cluster_number = i - 1;
                tt = ah_readTetData(getLocalPath(spikeFile), 'index', find(assignment == i));
                waveform = cellfun(@(x) mean(x, 2), tt.w, 'UniformOutput', false);
                tuple.mean_waveform = [waveform{:}];
                tuple.snr = max(cellfun(@(x) (max(x) - min(x)) / mean(std(x)), waveform));
                tuple.fp = mean(1 - p(assignment == i, i));
                tuple.fn = sum(p(assignment ~= i, i)) / sum(assignment == i);
                insert(sort.TetrodesMoGUnits, tuple);
            end
        end
    end
end
