%{
sort.KalmanParams (lookup) # Association of detection method with Kalman sorting parameters

param_id   : int unsigned # unique identifier for subject
-----
feature_name   : varchar(64)      # name of the feature
feature_num    : int unsigned     # number of features
drift_rate     : double           # drift rate
cluster_cost   : double           # clustering cost
tolerance      : double           # tolerance
df             : double           # degrees of freedom
cov_ridge      : double           # magnitude of ridge regression
dt_mu          : double           # time steps for mean update

comment=""     : varchar(140)     # comment

%}

classdef KalmanParams < dj.Relvar
    methods
        function self = KalmanParams(varargin)
            self.restrict(varargin{:});
        end
    end
end