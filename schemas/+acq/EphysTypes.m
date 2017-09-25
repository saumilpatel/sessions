%{
acq.EphysTypes (lookup)       # contains valid configurations of task, setup and subject

->acq.Subjects
setup                 : tinyint unsigned   # setup number
ephys_task            : varchar(63)        # name of the task
---
->acq.ArrayInfo
ephys_type            : enum("Utah", "Tetrodes", "SiliconProbes", "NonChronic Tetrode", "unknown") # type of ephys recording
default_detect_method_num     : tinyint unsigned   # default detect method
default_sort_method_num       : tinyint unsigned   # default spike sorting method
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
