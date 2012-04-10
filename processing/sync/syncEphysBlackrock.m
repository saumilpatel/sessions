function [stimDiode, rms, offset] = syncEphysBlackrock(stim, key)
% Synchronize a stimulation file to a Blackrock recording
% AE 2012-02-10

params.maxPhotodiodeErr = 3;  % RMS in ms after correction

if isempty(stim.events)
    stimDiode = stim;
    rms = -1;
    offset = 0;
    return  % empty file; nothing to do
end

% Get photodiode swap times
diodeSwapTimes = detectSwaps(key);

% swap times recorded on the Mac
macSwapTimes = cat(1, stim.params.trials.swapTimes);
macSwapTimes(1) = []; % for some reason the first swap doesn't seem to happen

% iteratively compute refresh rate
N = 50;
ms = macSwapTimes;
ds = diodeSwapTimes;
done = false;
macPar = regress(ds(1:N), [ones(N, 1), ms(1:N)]);
while ~done
    [msMatched, dsMatched] = matchTimes(ms(1:N), ds(1:N), macPar);
    macPar = regress(dsMatched, [ones(size(msMatched)), msMatched]);
    ms = [msMatched; ms(N+1:end)];
    ds = [dsMatched; ds(N+1:end)];
    if N >= min(length(ms), length(ds))
        done = true;
    else
        N = min(2 * N, min(length(ms), length(ds)));
    end
end

% convert times in stim file
stimDiode = convertStimTimes(stim, macPar, [0 1]);
stimDiode.synchronized = 'diode';

% Make sure we have at least one trial where all swap times are matched.
% This ensures that we're not off by a frame or two
macSwapTimes = cat(1, stimDiode.params.trials.swapTimes);
[macSwapTimes, diodeSwapTimes] = matchTimes(macSwapTimes, diodeSwapTimes, [0 1]);
i = 1;
while i <= numel(stim.params.trials)
    if all(ismember(stimDiode.params.trials(i).swapTimes, macSwapTimes))
        break
    end
    i = i + 1;
end
assert(i <= numel(stim.params.trials), ...
    ['No trial where all swap times were found in the photodiode signal. ' ...
    'This indicates that the regression is off by one or more frames!'])

% plot residuals
figure
res = macSwapTimes(:) - diodeSwapTimes(:);
plot(diodeSwapTimes, res, '.k');
rms = sqrt(mean(res.^2));
assert(rms < params.maxPhotodiodeErr, 'Residuals too large after synchronization to photodiode!');
fprintf('Residuals on photodiode regression had a range of %g and an RMS of %g ms\n', range(res), rms);

offset = -1; % irrelevant for these recordings


function [x, y] = matchTimes(x, y, b)

threshold = 3; % max 5 ms offset
i = 1; j = 1;
keepx = true(size(x));
keepy = true(size(y));
while i <= numel(x) && j <= numel(y)
    if b(1) + b(2) * x(i) < y(j) - threshold
        keepx(i) = false;
        i = i + 1;
    elseif b(1) + b(2) * x(i) > y(j) + threshold
        keepy(j) = false;
        j = j + 1;
    else
        i = i + 1;
        j = j + 1;
    end
end
keepx(i:end) = false;
keepy(j:end) = false;
y = y(keepy);
x = x(keepx);


function swapTimes = detectSwaps(key, varargin)

params.refresh = 60;
params.cropStart = 10; % crop off the first 10 seconds because psychtoolbox
                       % starts up with gray screen and when we set the
                       % background this is detected as a swap
params.filterOrder = 5;
params.threshold = 2;
params.chunkSize = 1e6;
params = parseVarArgs(params, varargin{:});

br = getFile(acq.Ephys(key), 'ac');
Fs = getSamplingRate(br);
startSample = Fs * params.cropStart; 
totalSamples = length(br) - startSample;

% preprocessing filter
[b, a] = butter(params.filterOrder, params.refresh / Fs * 2, 'low');

% process photodiode signal in chunks to detect buffer swaps
nChunks = ceil(totalSamples / params.chunkSize);

fprintf('Detecting photodiode peaks (%u chunks)\n', nChunks);
swapTimes = [];
for i = 1:nChunks
    % read data, lowpass filter, detect local maxima of slope
    first = startSample + (i - 1) * params.chunkSize;
    last = min(startSample + i * params.chunkSize, length(br));
    x = br(first+1:last, 1);
    y = filtfilt(b, a, x);
    dy = abs(diff(y));
    ddy = diff(dy);
    yp = find(ddy(1:end-1) > 0 & ddy(2:end) <= 0);
    yp = yp(dy(yp) > params.threshold);
    t = br(yp + first - 1, 't');
    swapTimes = [swapTimes; t(:)];    %#ok<AGROW>
    progress(i, nChunks, 20)
end
close(br);
