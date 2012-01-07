function processSession(sessKey, detectMethod, sortMethod)
% Process an acquisition session
%   processSession(sessKey)
%   processSession(sessKey, detectMethod, sortMethod)
%
% AE 2011-11-11

if nargin < 2, detectMethod = []; end
if nargin < 3, sortMethod = []; end

% do a cleanup before processing 
% fixes missing stop_times and updates the t0 in the raw data files
populate(acq.SessionsCleanup, sessKey);

% find stimulation sessions that were recorded
populate(acq.EphysStimulationLink, sessKey);

% synchronize stimualtions
populate(acq.StimulationSync, sessKey);

% process ephys recordings
ephysKeys = fetch(acq.Ephys(sessKey));
n = numel(ephysKeys);
for i = 1:n
    [ts, te] = fetch1(acq.Ephys(ephysKeys(i)), 'ephys_start_time', 'ephys_stop_time');
    mins = round((te - ts) / 1000 / 60);
    hours = floor(mins / 60);
    mins = rem(mins, 60);
    fprintf('Process session %d of %d (duration: %d:%d h)? [Y/n] ', i, n, hours, mins);
    answer = input('', 's');
    if lower(answer(1)) == 'y'
        detectKey = createDetectSet(ephysKey, detectMethod);
        createSortSet(detectKey, sortMethod);
    end
end
