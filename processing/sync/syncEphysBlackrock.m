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

% deal with some details of how photodiode signal is handled in acute
% experiments. not all frames are registered
switch fetch1(acq.Stimulation & key, 'exp_type')
    case 'AcuteGratingExperiment'
        % for some reason the first swap doesn't show up. We add a fake
        % first swap
        d = diff(macSwapTimes);
        periodMac = mean(d(d < 0.025));
        periodDiode = median(diff(diodeSwapTimes(1 : 100)));
        first = round(diff(macSwapTimes(1 : 2)) / periodMac) * periodDiode;
        diodeSwapTimes = [diodeSwapTimes(1) - first; diodeSwapTimes(1 : end - 3)];
    case 'SquareMappingExperiment'
        % swap timer was modified by Wangchen such that it changes polarity
        % only during the stimulus loop
        ndx = find(diff(macSwapTimes) > 1, 1);
        macSwapTimes = macSwapTimes(ndx + 1 : end - 1);
end
assert(numel(macSwapTimes) == numel(diodeSwapTimes), 'Not all swaps found in photodiode signal. Chaos!!!')

% compute regression iteratively by removing all non-matches
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

macSwapTimes = cat(1, stimDiode.params.trials.swapTimes);
d = diff(macSwapTimes);
period = mean(d(d < 25));

% detect dropped frames
offset = round((diodeSwapTimes - macSwapTimes) / period);
drop = find(offset, 1);
while ~isempty(drop)
    n = [0 cumsum(arrayfun(@(x) numel(x.swapTimes), stimDiode.params.trials))];
    trial = find(drop < n, 1) - 1;
    frame = drop - n(trial);
    
    
    % adjust timestamps in trial where missed frame occurred
    shift = period * offset(drop);
    ts = stimDiode.params.trials(trial).swapTimes;
    ts(frame : end) = ts(frame : end) + shift;
    stimDiode.params.trials(trial).swapTimes = ts;
    et = stimDiode.events(trial).times;
    et(et >= ts(frame)) = et(et >= ts(frame)) + shift;
    stimDiode.events(trial).times = et;
    
    % adjust timestamps in remaining trials
    for i = trial + 1 : length(stimDiode.events)
        stimDiode.events(i).times = stimDiode.events(i).times + shift;
        stimDiode.params.trials(i).swapTimes = stimDiode.params.trials(i).swapTimes + shift;
    end
    
    % insert into database
    tuple = key;
    tuple.trial_num = trial;
    tuple.frame_num = frame;
    tuple.shift = offset(drop);
    inserti(acq.FrameDrops, tuple)
    
    macSwapTimes = cat(1, stimDiode.params.trials.swapTimes);
    offset = round((diodeSwapTimes - macSwapTimes) / period);
    drop = find(offset, 1);
end

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
params.chunkSize = 1e6;
params.warmup = 1e4;
params = parseVarArgs(params, varargin{:});

br = getFile(acq.Ephys(key), 'ac');
Fs = getSamplingRate(br);
startSample = Fs * params.cropStart; 
totalSamples = length(br) - startSample;

% preprocessing filter
[b, a] = butter(params.filterOrder, params.refresh / Fs * 2, 'low');

% process photodiode signal in chunks to detect buffer swaps
nChunks = ceil(totalSamples / params.chunkSize);

% determine threshold (using a chunk of data in the middle)
first = startSample + nChunks / 2 * params.chunkSize;
last = first + params.chunkSize;
x = br(first+1:last, 1);
y = filtfilt(b, a, x);
m = median(y);

fprintf('Detecting photodiode peaks (%u chunks)\n', nChunks);
swapTimes = [];
warmup = zeros(params.warmup, 1);
for i = 1:nChunks
    % read data, lowpass filter, detect local maxima of slope
    first = startSample + (i - 1) * params.chunkSize;
    last = min(startSample + i * params.chunkSize, length(br));
    x = [warmup; br(first+1:last, 1)];
    y = filtfilt(b, a, x);
    yp = find(sign(y(1 : end - 1) - m) ~= sign(y(2 : end) - m));
    yp = yp(yp > params.warmup / 2 & yp <= params.chunkSize + params.warmup / 2);
    warmup = x(end - params.warmup + 1 : end);
    t = br(yp + first - params.warmup, 't');
    swapTimes = [swapTimes; t(:)];    %#ok<AGROW>
    progress(i, nChunks, 20)
end
close(br);
