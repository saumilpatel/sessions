%{
sort.KalmanManual (computed) # my newest table
-> sort.KalmanAutomatic
-----
manual_model: LONGBLOB # The finalized model
kalmanmanual_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
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
            % Cluster spikes
            %
            % JC 2011-10-21
            tuple = key;
            
            model = getModel(sort.KalmanTemp & key);
 
            m = MoKsmInterface(model);
            m = ManualClustering(m,fetch1(detect.Electrodes & key, 'detect_electrode_file'));
            
            tuple.manual_model = saveStructure(compress(m));
            insert(this,tuple);
                       
            % Delete the temporary structure
            % Err can't do this because we are already in a transaction
            %del(sort.KalmanTemp & key, false);
        end
    end
end
