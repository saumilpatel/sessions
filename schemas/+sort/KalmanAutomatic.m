%{
sort.KalmanAutomatic (computed) # my newest table

-> sort.Electrodes
---
-> sort.KalmanParams
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

            % Obtain detection method dependent parameters
            params = fetch(sort.KalmanParams & sort.KalmanDefault(de_key), '*');
               
            m = getFeatures(m, params.feature_name, params.feature_num);
            
            m.params.DriftRate = params.drift_rate;
            m.params.ClusterCost = params.cluster_cost;
            m.params.Df = params.df;
            m.params.Tolerance = params.tolerance;
            m.params.CovRidge = params.cov_ridge;
            m.params.DTmu = params.dt_mu;
            
            fprintf('Fetched sorting parameters\n');
            
            fitted = fit(m);
            plot(fitted);
            drawnow
            
            tuple = key;
            tuple.param_id = params.param_id;
            tuple.model = saveStructure(compress(fitted));
            tuple.git_hash = gitHash('MoKsm');
            insert(this, tuple);
            
            makeTuples(sort.KalmanTemp, key, fitted);
        end
    end
end
