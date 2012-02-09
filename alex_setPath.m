function setPath

warning off MATLAB:dispatcher:nameConflict

if isequal(computer, 'PCWIN64')
    addpath(getLocalPath('/lab/libraries/mym/win64'))
else
    addpath(getLocalPath('/lab/libraries/mym'))
end

% This will use Alex' credentials to access the database
addpath(getLocalPath('/lab/users/alex'))

base = fileparts(mfilename('fullpath'));
addpath(fullfile(base, 'processing'))
addpath(fullfile(base, 'processing/sync'))
addpath(fullfile(base, 'processing/utils'))
addpath(fullfile(base, 'recovery'))
addpath(fullfile(base, 'schemas'))
addpath(fullfile(base, 'migration'))

% DataJoint library is assumed to be in the same directory as the base
% diretory
ndx = find(base == filesep, 1, 'last');
addpath(fullfile(base(1:ndx-1), 'datajoint/matlab'))

% TEMP until updated on /lab/libraries
run(fullfile(base(1:ndx-1), 'hdf5matlab/setPath.m'))

% spike detection
run(fullfile(base(1:ndx-1), 'detection/setPath.m'))

% LFP
addpath(fullfile(base(1:ndx-1), 'lfp'))

% spike sorting
addpath(fullfile(base(1:ndx-1),'clustering'))
run(getLocalPath('/lab/libraries/various/spider/use_spider'))

warning on MATLAB:dispatcher:nameConflict
