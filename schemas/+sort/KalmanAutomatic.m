%{
sort.KalmanAutomatic (computed) # my newest table

-> sort.Electrodes
---
model                       : longblob                      # The fitted model
git_hash=""                 : varchar(40)                   # git hash of MoKsm package
kalmanautomatic_ts=CURRENT_TIMESTAMP: timestamp             # automatic timestamp. Do not edit
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

    methods (Access=protected)
        function makeTuples( this, key )
            % Cluster spikes
            
            de_key = fetch(detect.Electrodes(key));
            
            m = MoKsmInterface(de_key);
            m = getFeatures(m,'PCA');

            % Parameters for sorting. Those were tweaked for tetrode
            % recordings. Other types of data may need substantial
            % adjustments... [AE]
            m.params.ClusterCost = 0.0023;
            m.params.Df = 5;
            m.params.CovRidge = 1.5;
            m.params.DriftRate = 400 / 3600 / 1000;
            m.params.DTmu = 60 * 1000;
            m.params.Tolerance = 0.0005;
            m.params.Verbose = true;

            fitted = fit(m);
            plot(fitted);
            drawnow
            
            tuple = key;
            tuple.model = saveStructure(compress(fitted));
            tuple.git_hash = gitHash('MoKsm');
            insert(this, tuple);
            
            makeTuples(sort.KalmanTemp, key, fitted);
        end
    end
end
