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
            
            % Reference electrodes in chronic tetrode drives need to be
            % treated differently
            detectMethod = fetch1(detect.Methods & de_key, 'detect_method_name');
            if any(strcmp(detectMethod, {'Tetrodes', 'TetrodesV2'})) && numel(m.tt.w) == 1
                m = getFeatures(m, 'PCA', 4);
                m.params.DriftRate = 100 / 3600 / 1000;
                m.params.ClusterCost = 0.002;
                m.params.Df = 5;
                m.params.Tolerance = 0.0005;
                m.params.CovRidge = 1.5;
                m.params.DTmu = 60 * 1000;
            else
                m = getFeatures(m, params.feature_name, params.feature_num);
                m.params.DriftRate = params.drift_rate;
                m.params.ClusterCost = params.cluster_cost;
                m.params.Df = params.df;
                m.params.Tolerance = params.tolerance;
                m.params.CovRidge = params.cov_ridge;
                m.params.DTmu = params.dt_mu;
                fprintf('Fetched sorting parameters\n');
            end
            
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
