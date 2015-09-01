%{
sort.Experimenter (manual) # my newest table
experimenter_id   : int unsigned # unique identifier for experimenter
---
experimenter_name : varchar(255) # name of the experimenter
experimenter_email = "": varchar(255) # email of the experimenter
%}

classdef Experimenter < dj.Relvar
    methods
        function self = Experimenter(varargin)
            self.restrict(varargin{:});
        end
    end
end

