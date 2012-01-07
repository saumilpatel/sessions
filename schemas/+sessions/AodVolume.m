%{
sessions.AodVolume (manual) # electrophysiology recordings

-> sessions.Sessions
aod_volume_start_time: bigint                         # start session timestamp
---
aod_volume_stop_time=null        : bigint             # end of session timestamp
aod_volume_filename              : varchar(255)       # path to the ephys data
x_coordinate                     : double             # X coordinate of the manipulator 
y_coordinate                     : double             # Y coordinate of the manipulator 
z_coordinate                     : double             # Z coordinate of the manipulator 
objective                        : enum('20x')        # Objective used
x_range                          : double             # X volume range
y_range                          : double             # Y volume range
z_range                          : double             # Z volume range
x_resolution                     : double             # X volume resolution
y_resolution                     : double             # Y volume resolution
z_resolution                     : double             # Z volume resolution
reps                             : int unsigned       # Z volume resolution
pmt_green                      : double             # Setting for green PMT
pmt_red                        : double             # Setting for red PMT
preamplifier_green  : enum('10e-5','10e-6','10e-7')  # preamp setting
preamplifier_red    : enum('10e-5','10e-6','10e-7')  # preamp setting
attenuator_degrees             : double             # Attenautor setting
scan_power                     : double             # Power out of object in mW
depth                          : double             # Depth below surface in microns
gdd                            : double             # GDD compensation
%}

classdef AodVolume < dj.Relvar
    properties(Constant)
        table = dj.Table('sessions.AodVolume');
    end
    
    methods 
        function self = AodScan(varargin)
            self.restrict(varargin{:})
        end
    end
end
