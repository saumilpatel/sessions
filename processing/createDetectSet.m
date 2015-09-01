function detectKey = createDetectSet(ephysKey, detectMethod, useToolchain)
% Create spike detection set for ephys recording
%   detectKey = createDetectSet(ephysKey) creates a spike detection set for
%   the given ephys recording using the detect_method_num defined in
%   acq.EphysTypes.
%
%   detectKey = createDetectSet(ephysKey, detectMethod) uses the non-
%   default detectMethod.
%
% AE 2011-11-11

detectKey = ephysKey;
if nargin < 2 || isempty(detectMethod)
    detectKey.detect_method_num = fetch1(acq.Ephys(ephysKey) * acq.EphysTypes, 'default_detect_method_num');
else
    detectKey.detect_method_num = fetch1(detect.Methods(struct('detect_method_name', detectMethod)), 'detect_method_num');
end
if count(detect.Params(detectKey))
    fprintf('Detection set exists already.\n')
    return
end
if nargin < 3
    useToolchain = true;
end
tuple = detectKey;
ephysFolder = fileparts(fetch1(acq.Ephys(ephysKey), 'ephys_path'));
if strcmp(getenv('DJ_HOST'), 'at-backupdb')
    tuple.ephys_processed_path = to(RawPathMap, ephysFolder, '/processedBackupdb');
else
    tuple.ephys_processed_path = to(RawPathMap, ephysFolder, '/processed');
end
tuple.use_toolchain = useToolchain;
insert(detect.Params, tuple);
