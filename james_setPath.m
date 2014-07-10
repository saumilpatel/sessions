function setPath

warning off MATLAB:dispatcher:nameConflict

% user specific DJ connection parameters (uses Alex' credentials)
host = 'at-database.neusc.bcm.tmc.edu';
user = 'jcotton';
setenv('DJ_HOST', host)
setenv('DJ_USER', user)
fprintf('Datajoint connection\n')
fprintf('--------------------\n')
fprintf('host: %s\n', host)
fprintf('user: %s\n\n', user)

base = fileparts(mfilename('fullpath'));
addpath(fullfile(base, 'processing'))
addpath(fullfile(base, 'processing/sync'))
addpath(fullfile(base, 'processing/utils'))
addpath(fullfile(base, 'recovery'))
addpath(fullfile(base, 'schemas'))
addpath(fullfile(base, 'migration'))
addpath(fullfile(base, 'sortgui'))
addpath(fullfile(base, 'sortgui/lib'))
addpath(fullfile(base, 'aodgui'))
addpath(fullfile(base, 'lib/two_photon'))

% DataJoint library is assumed to be in the same directory as the base
% diretory
%addpath(fullfile(base, '../DataJoint/matlab'));
addpath('z:\users\alex\projects\datajoint\')
addpath('Z:\users\alex\projects\mym\distribution\mexw64')

addpath(fullfile(base, '../moksm'));


if isequal(computer, 'PCWIN64')
    %addpath(fullfile(base, '../DataJoint/mym/win64'));
else
    %addpath(fullfile(base, '../DataJoint/mym'));
end


if exist(getLocalPath('/lab/'), 'dir')
    % TEMP until updated on /lab/libraries
    run(getLocalPath('/lab/libraries/hdf5matlab/setPath'))
    
    % LFP
    addpath(getLocalPath('/lab/libraries/lfp'));
    
    % spike sorting
    addpath(getLocalPath('/lab/users/james/Matlab/VariationalClustering'));
    
    % spike detection
    %run(getLocalPath('/lab/users/james/Matlab/spikesorting/detection/setPath'));
    run C:\Users\jcotton\Documents\MATLAB\spikedetection\setPath.m

    warning on MATLAB:dispatcher:nameConflict
else
    warning('at-lab not mounded.  File access tools not added to path');
end
