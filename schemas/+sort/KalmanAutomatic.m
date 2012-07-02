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
        popRel = sort.Electrodes * sort.Methods('sort_method_name = "MoKsm"');
    end
    
    methods
        function self = KalmanAutomatic(varargin)
            self.restrict(varargin)
        end
    end
    
    methods (Access=protected):
        function makeTuples( this, key )
            % Cluster spikes
            %
            % JC 2011-10-21
            close all
            tuple = key;
            
            de_key = fetch(detect.Electrodes(key));
            
            m = MoKsmInterface(de_key);
            if length(m.Waveforms.data) > 1
                m = getFeatures(m,'PCA');
            else
                m = getFeatures(m,'Points');
            end
            clustCosts = 0.05; %[0.01 0.03 0.05];
            for i = 1:length(clustCosts)
                m.params.Verbose = true;
                m.params.ClusterCost = clustCosts(i)
                fitted = fit(m);
                marray(i) = saveStructure(compress(fitted));
                
                plot(fitted);
                pause(1)
            end
            tuple.model = struct(marray);
            insert(this,tuple);
            
        end
    end
end
