
%{
sessions.EphysTypes (lookup)       # contains valid configurations of task, setup and subject

->sessions.Subjects
setup      : tinyint unsigned # setup number
ephys_task : varchar(63)      # name of the task
---
ephys_type : enum("Utah", "Tetrodes", "SiliconProbes") # type of ephys recording
%}

classdef EphysTypes < dj.Relvar
    properties(Constant)
        table = dj.Table('sessions.EphysTypes');
    end
    
    methods 
        function self = EphysTypes(varargin)
            self.restrict(varargin{:})
        end
    end
end