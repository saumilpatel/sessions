%{
sort.Automatic (imported) # clustering for one electrode

->sort.Electrodes
---
%}

classdef Automatic < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('sort.Automatic');
        popRel = sort.Electrodes;
    end
    
    methods 
        function self = Automatic(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            sortMethod = fetch1(sort.Params(key) * sort.Methods, 'sort_method_name');
            spikesPath = fetch1(detect.Sets(key), 'detect_set_path');
            outPath = fetch1(sort.Sets(key), 'sort_set_path');
            switch sortMethod
                case 'TetrodesMoG'
                    backupPath = strrep(outPath, '/processed/', '/stor01/clustered/');
                    job = clus_enqueue_jobs([], spikesPath, key.electrode_num, outPath, backupPath);
                    clus_run_job(job);
                otherwise
                    error('Method %s not implemented yet!', sortMethod)
            end
            self.insert(key);
        end
    end
end
