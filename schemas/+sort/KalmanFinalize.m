%{
sort.KalmanFinalize (computed) # my newest table
-> sort.KalmanAutomatic
-----
final_model: LONGBLOB # The finalized model
kalmanautomatic_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef KalmanFinalize < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('sort.KalmanFinalize')
		popRel = sort.KalmanAutomatic;
	end

	methods
		function self = KalmanFinalize(varargin)
			self.restrict(varargin)
        end
    end
    
    methods (Access=protected)
        function makeTuples( this, key )
            % Cluster spikes
            %
            % JC 2011-10-21
            close all
            tuple = key;
            
            model = fetch1(sort.KalmanAutomatic(key),'model');
            model = model(1);
 
            m = MoKsmInterface(model);
            m = uncompress(m);
            m = updateInformation(m);
            m = ManualClustering(m,fetch1(detect.Electrodes & key, 'detect_electrode_file'));
            
            tuple.final_model = saveStructure(compress(m));
            insert(this,tuple);
           
            % Insert entries for the single units
            makeTuples(sort.KalmanUnits, key, m);
        end
    end
end
