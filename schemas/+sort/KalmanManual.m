%{
sort.KalmanManual (computed) # manual processing step

-> sort.KalmanAutomatic
---
manual_model                : longblob                      # The manually processed model
kalmanmanual_ts=CURRENT_TIMESTAMP: timestamp                # automatic timestamp. Do not edit
comment=""                  : varchar(255)                  # comment on manual step
%}

classdef KalmanManual < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('sort.KalmanManual')
        popRel = sort.KalmanAutomatic & sort.KalmanTemp;
    end
    
    methods
        function self = KalmanManual(varargin)
            self.restrict(varargin)
        end        
    end

    methods (Access=protected)
        function makeTuples( this, key )

            model = getModel(sort.KalmanTemp & key);
            model.params.Verbose = false;
 
            m = MoKsmInterface(model);
            [m, comment] = ManualClustering(m, fetch1(detect.Electrodes & key, 'detect_electrode_file'));
            
            if ~isempty(m)
                tuple = key;
                tuple.manual_model = saveStructure(compress(m));
                tuple.comment = comment(1 : min(end, 255));
                insert(this, tuple);
            else
                warning('KalmanAutomatic:canceled', 'Manual processing canceled. Not inserting anything!')
            end
        end
    end
end
