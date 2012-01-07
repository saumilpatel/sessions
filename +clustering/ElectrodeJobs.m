%{
clustering.ElectrodeJobs(computed)   # jobs run at the end of each experiment
-> ephys.DetectionElectrode
<<JobFields>>
%}

classdef ElectrodeJobs < dj.Relvar
    properties(Constant)
        table = dj.Table('clustering.ElectrodeJobs')
    end
    methods
        function self = ElectrodeJobs(varargin)
            self.restrict(varargin) 
        end
    end
end
%}