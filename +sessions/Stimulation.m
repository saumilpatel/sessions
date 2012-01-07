%{
sessions.Stimulation (manual) # Stimulation tables

-> sessions.Sessions
stim_start_time : bigint                #
---
stim_stop_time=null         : bigint                        #
stim_path                   : varchar(255)                  #
exp_type                    : varchar(45)                   #
total_trials=null           : int                           #
correct_trials=null         : int                           #
incorrect_trials=null       : int                           #
%}

classdef Stimulation < dj.Relvar
    properties(Constant)
        table = dj.Table('sessions.Stimulation');
    end
    
    methods
        function self = Stimulation(varargin)
            self.restrict(varargin{:})
        end
        
        function [fn stimFiles] = getStimFile(self, variant)
            % Returns the stimulation file name and file.  Accepts an optional variant
            % liked Synced to postpend to name
            %
            % [fn stimFiles] = getStimFile(sDb, stim, variant)d
            %
            % JC 2011-08
            
            if (nargin < 2)
                variant = '';
            end
            
            stim = fetch(self, 'stim_path', 'exp_type');
            for i = 1:length(stim)
                fn{i} = getLocalPath([stim(i).stim_path '/' stim(i).exp_type variant '.mat']);
                stimFiles(i) = getfield(load(fn{i}),'stim');
            end
        end
        
    end
end
