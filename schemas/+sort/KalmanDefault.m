%{
sort.KalmanDefault (lookup) # Assignment of default Kalman sorting params to detection method
-> detect.Methods
-----
-> sort.KalmanParams
%}

classdef KalmanDefault < dj.Relvar
    methods
        function self=KalmanDefault(varargin)
            self.restrict(varargin{:});
        end
    end
end

