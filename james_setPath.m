function setPath

warning off MATLAB:dispatcher:nameConflict

if isequal(computer, 'PCWIN64')
    addpath(getLocalPath('/lab/libraries/mym/win64'))
else
    addpath(getLocalPath('/lab/libraries/mym'))
end

base = fileparts(mfilename('fullpath'));
addpath(base);
addpath(fullfile(base, 'processing'))
%addpath(fullfile(base, 'processing/sync'))
%addpath(fullfile(base, 'processing/utils'))
addpath(fullfile(base, 'recovery'))
addpath(fullfile(base, 'schemas'))
addpath(fullfile(base, 'migration'))
addpath(fullfile(base, 'sync'));

% DataJoint library is assumed to be in the same directory as the base
% diretory
addpath(getLocalPath('/lab/libraries/datajoint2'))

% TEMP until updated on /lab/libraries
run(getLocalPath('/lab/libraries/hdf5matlab/setPath'))

% LFP
addpath(getLocalPath('/lab/libraries/lfp'));

% spike sorting
addpath(getLocalPath('/lab/users/james/Matlab/VariationalClustering'));

% spike detection
run(getLocalPath('/lab/users/james/Matlab/spikesorting/detection/setPath'));

warning on MATLAB:dispatcher:nameConflict
