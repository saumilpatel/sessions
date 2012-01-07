%{
sort.Jobs (computed)   # spike sorting jobs
-> sort.Electrodes
<<JobFields>>
%}

classdef Jobs < dj.Relvar
    properties(Constant)
        table = dj.Table('sort.Jobs')
    end
    methods
        function self = Jobs(varargin)
            self.restrict(varargin)
        end
    end
end
