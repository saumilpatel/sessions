%{
acq.EphysTypes (lookup)       # contains valid configurations of task, setup and subject

->acq.Subjects
setup                 : tinyint unsigned   # setup number
ephys_task            : varchar(63)        # name of the task
---
ephys_type            : enum("Utah", "Tetrodes", "SiliconProbes") # type of ephys recording
->detect.Methods
->sort.Methods
%}

classdef EphysTypes < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.EphysTypes');
    end
    
    methods 
        function self = EphysTypes(varargin)
            self.restrict(varargin{:})
        end
    end
end
