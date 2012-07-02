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

        function makeTuples( this, key )
            % Cluster spikes
            %
            % JC 2011-10-21
            close all
            tuple = key;
            
            model = fetch1(sort.KalmanAutomatic(key),'model');
            model = model(1);
            
            m = MoKsmInterface(key);
            if length(m.Waveforms.data) > 1
                m = getFeatures(m,'PCA');
            else
                m = getFeatures(m,'Points');
            end
            
            fields = {'params','model','Y','t','train','test','blockId','spikeId'};
            for i = 1:length(fields)
                m.(fields{i}) = model.(fields{i});
            end
            m = updateInformation(m);
            m = ManualClustering(m,fetch1(detect.Electrodes & key, 'detect_electrode_file'));
            tuple.model = struct(m);
            insert(this,tuple);
        end
    end
end
