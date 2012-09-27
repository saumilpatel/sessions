%{
sort.TetrodesMoGAutomatic (imported) # automatic MoG clustering step

->sort.Electrodes
---
%}

classdef TetrodesMoGAutomatic < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('sort.TetrodesMoGAutomatic');
        popRel = sort.Electrodes * sort.Methods('sort_method_name = "TetrodesMoG"');
    end
    
    methods 
        function self = TetrodesMoGAutomatic(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            spikesPath = fetch1(detect.Sets(key), 'detect_set_path');
            outPath = fetch1(sort.Sets(key), 'sort_set_path');
            backupPath = strrep(outPath, '/processed/', '/stor01/clustered/');
            job = clus_enqueue_jobs([], spikesPath, key.electrode_num, outPath, backupPath);
            clus_run_job(job);
            self.insert(key);
        end
    end
end
