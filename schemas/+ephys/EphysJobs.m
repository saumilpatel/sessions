%{
ephys.EphysJobs(computed)   # jobs run at the end of each experiment
-> sessions.Ephys
<<JobFields>>
%}

classdef EphysJobs < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.EphysJobs')
    end
    methods
        function self = EphysJobs(varargin)
            self.restrict(varargin) 
        end
        
        function run(self)
            % start job management
            s = ephys.getSchema;
            s.manageJobs(ephys.StimJobs);
            
            populate(ephys.SpikeSet);
            populate(ephys.SpikesAlignedSet);
            populate(ephys.SpikesBinnedSet);

            % stop job management 
            s.manageJobs
        end
    end
end
%}