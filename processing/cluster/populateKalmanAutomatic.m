function populateKalmanAutomatic(varargin)

varargin{:}
pause(rand * 10) % make sure they don't all start at the same time
addpath ~
addpath /home/toliaslab/libraries/matlab
run /home/toliaslab/users/alex/projects/acq/alex_setPath.m
parPopulate(sort.KalmanAutomatic, sort.Jobs, varargin{:})
