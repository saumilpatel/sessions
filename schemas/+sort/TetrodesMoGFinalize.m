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
        
        function makeTuples(self, key)
            % do model refit
            sortPath = fetch1(sort.Sets(key), 'sort_set_path');
            resultFile = fullfile(getLocalPath(sortPath), ...
                sprintf('resultTT%d.mat', key.electrode_num));
            job = getfield(load(resultFile, 'job'), 'job'); %#ok
            job.status = 2;
            clus_runPostProcessing(job);
            insert(self, key);
            
            % insert single units into TetrodesMoGUnits
            clusFile = fullfile(getLocalPath(sortPath), ...
                sprintf('clusteringTT%d.mat', key.electrode_num));
            clus = getfield(load(clusFile), 'clustering'); %#ok
            for i = 1:clus.nbClusters
                tuple = key;
                tuple.cluster_number = i;
                insert(sort.TetrodesMoGUnits, tuple);
            end
        end
    end
end
