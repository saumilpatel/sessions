%{
sort.KalmanPractice (computed) # For sorting practice (you dummy...)
-> sort.KalmanAutomatic
-> sort.Experimenter
-----
manual_model                       :longblob                  # The manually processed model
kalmanmanual_ts=CURRENT_TIMESTAMP  : timestamp                # automatic timestamp. Do not edit
comment=""                         : varchar(255)                    # comment on manual step
%}


classdef KalmanPractice < dj.Relvar & dj.AutoPopulate
    properties
        popRel = sort.KalmanAutomatic * sort.Experimenter & sort.KalmanTemp;
    end
    
	methods
        function self = KalmanPractice(varargin)
            self.restrict(varargin)
        end
        
        function review(self)
            % Review manual clustering model
            
            assert(count(self) == 1, 'relvar must be scalar!')
            disp 'Review only. No changes will take effect!'
            disp 'If you need to change something, delete the tuple and redo it.'
            ename = fetch1(sort.Experimenter & key, 'experimenter_name');
            file = fetch1(detect.Electrodes & key, 'detect_electrode_file');
            title = sprintf('|| READ ONLY || Operator: %s | File: %s || READ ONLY ||', ename, file);
            model = uncompress(MoKsmInterface(fetch1(self, 'manual_model')));
            ManualClustering(model, title)
        end
    end
    
    methods (Access=protected)
		function makeTuples( this, key )
            model = getModel(sort.KalmanTemp & key);
            model.params.Verbose = false;
 
            model = MoKsmInterface(model);
            ename = fetch1(sort.Experimenter & key, 'experimenter_name');
            file = fetch1(detect.Electrodes & key, 'detect_electrode_file');
            title = sprintf('Operator: %s | File: %s', ename, file);
            [model, comment] = ManualClustering(model, title);
            
            if ~isempty(model)
                tuple = key;
                tuple.manual_model = saveStructure(compress(model));
                tuple.comment = comment(1 : min(end, 255));
                insert(this, tuple);
            else
                warning('KalmanAutomatic:canceled', 'Manual processing canceled. Not inserting anything!')
            end
        end
	end

end
