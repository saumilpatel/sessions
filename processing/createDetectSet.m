function detectKey = createDetectSet(ephysKey, detectMethod)
% Create spike detection set for ephys recording
%   detectKey = createDetectSet(ephysKey) creates a spike detection set for
%   the given ephys recording using the default_detect_method defined in
%   acq.EphysTypes.
%
%   detectKey = createDetectSet(ephysKey, detectMethod) uses the non-
%   default detectMethod.
%
% AE 2011-11-11

detectKey = ephysKey;
if nargin < 2 || isempty(detectMethod)
    detectKey.detect_method_num = fetch1(acq.Ephys(ephysKey) * acq.EphysTypes, 'default_detect_method');
else
    detectKey.detect_method_num = fetch1(detect.Methods(struct('detect_method_name', detectMethod)), 'detect_method_num');
end
if count(detect.Params(detectKey))
    fprintf('Detection set exists already.\n')
    return
end
tuple = detectKey;
ephysFolder = fileparts(fetch1(acq.Ephys(ephysKey), 'ephys_path'));
tuple.ephys_processed_path = to(RawPathMap, ephysFolder, '/processed');
insert(detect.Params, tuple);
