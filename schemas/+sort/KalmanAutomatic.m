%{
sort.KalmanAutomatic (computed) # my newest table
-> sort.Electrodes
-----
model: LONGBLOB # The fitted model
kalmanautomatic_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef KalmanAutomatic < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('sort.KalmanAutomatic')
		popRel = sort.Electrodes
	end

	methods
		function self = KalmanAutomatic(varargin)
			self.restrict(varargin)
		end

        function makeTuples( this, key )
            % Cluster spikes
            %
            % JC 2011-10-21
            
            tuple = key;
            
            de_keys = fetch(detect.Electrodes(key));
            
            for de_key = de_keys'
                m = MoKsm(de_key,'driftRate',1e-8 / 10);
                if length(m.data.Waveforms.data) > 1
                    m = getFeatures(m,'PCA');
                else
                    m = getFeatures(m,'Points');
                end
                m.params.verbose = true;
                m = fitModel(m);
                m.data = rmfield(m.data, 'Waveforms');
                tuple.model = struct(m);

                insert(this,tuple);
            end
        end
    end
end
