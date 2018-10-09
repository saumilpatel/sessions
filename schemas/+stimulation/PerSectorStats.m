%{
# table that holds per sector behavior analysis in saccadeflashexperiment
-> stimulation.StimTrialGroup
dot_contrast                : decimal(4,1)                  # contrast of stim
bipolar_contrast            : tinyint                       # set to 1 for both poklarities
---
session_sector_trials=null  : blob                          # entire analysis
%}


classdef PerSectorStats < dj.Manual
end