%{
sessions.AodScan (manual) # electrophysiology recordings

-> sessions.Sessions
aod_scan_start_time: bigint                         # start session timestamp
---
aod_scan_stop_time=null        : bigint             # end of session timestamp
aod_scan_filename              : varchar(255)       # path to the ephys data
x_coordinate                   : double             # X coordinate
y_coordinate                   : double             # Y coordinate
z_coordinate                   : double             # Z coordinate
objective                      : enum('20x')        # Objective used
motion_planes                  : tinyint            # 
pmt_green                      : double             # Setting for green PMT
pmt_red                        : double             # Setting for red PMT
preamplifier_green  : enum('10e-5','10e-6','10e-7')  # preamp setting
preamplifier_red    : enum('10e-5','10e-6','10e-7')  # preamp setting
attenuator_degrees             : double             # Attenautor setting
scan_power                     : double             # Power out of object in mW
depth                          : double             # Depth below surface in microns
gdd                            : double             # GDD compensation
%}

classdef AodScan < dj.Relvar
    properties(Constant)
        table = dj.Table('sessions.AodScan');
    end
    
    methods 
        function self = AodScan(varargin)
            self.restrict(varargin{:})
        end
    end
end
