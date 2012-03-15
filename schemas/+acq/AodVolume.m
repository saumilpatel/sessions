%{
acq.AodVolume (manual) # Aod volume recordings

-> acq.Sessions
aod_volume_start_time: bigint           # start session timestamp
---
aod_volume_stop_time=null   : bigint                        # end of session timestamp
aod_volume_filename         : varchar(255)                  # path to the ephys data
x_coordinate                : double                        # X coordinate of the manipulator
y_coordinate                : double                        # Y coordinate of the manipulator
z_coordinate                : double                        # Z coordinate of the manipulator
objective                   : enum('20x')                   # Objective used
x_range                     : double                        # X volume range
y_range                     : double                        # Y volume range
z_range                     : double                        # Z volume range
x_resolution                : double                        # X volume resolution
y_resolution                : double                        # Y volume resolution
z_resolution                : double                        # Z volume resolution
reps                        : int unsigned                  # Z volume resolution
pmt_green                   : double                        # Setting for green PMT
pmt_red                     : double                        # Setting for red PMT
preamplifier_green          : enum('10e-5','10e-6','10e-7') # preamp setting
preamplifier_red            : enum('10e-5','10e-6','10e-7') # preamp setting
attenuator_degrees          : double                        # Attenautor setting
scan_power                  : double                        # Power out of object in mW
depth                       : double                        # Depth below surface in microns
gdd                         : double                        # GDD compensation
%}


classdef AodVolume < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.AodVolume');
    end
    
    methods 
        function self = AodVolume(varargin)
            self.restrict(varargin{:})
        end
        
        function fileName = getFileName(self, varargin)
            % Get name of stimulation file for tuple in relvar
            %   fileName = getStimFile(self, [variant]) returns the file
            %   name matching the tuple in self. If the string variant is
            %   passed as second input it is appended at the end of the
            %   file name (e.g. 'Synched').
            [stimPath, expType] = fetch1(self, 'stim_path', 'exp_type');
            fileName = getLocalPath([stimPath '/' expType varargin{:} '.mat']);
        end
        
        function [stim, fileName] = getStim(self, varargin)
            % Load stimulation file for tuple in relvar
            %   [stim, fileName] = getStimFile(self, [variant]) returns the
            %   stimulation structure matching the tuple in self. If the
            %   string variant is passed as second input it is appended at
            %   the end of the file name (e.g. 'Synched').
            fileName = getFileName(self, varargin{:});
            stim = getfield(load(fileName), 'stim'); %#ok
        end
    end
end
