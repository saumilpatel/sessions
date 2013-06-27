function [stimDiode, rms, offset] = syncEphysBlackrock(stim, key)
% Synchronize a stimulation file to a Blackrock recording
% AE 2012-02-10

% Get photodiode swap times
diodeSwapTimes = detectSwaps(key);

% swap times recorded on the Mac
[macSwapTimes, nskip] = getMacSwapTimes(stim);

% for some reason the first swap doesn't show up. We add a fake first swap
if strcmp(fetch1(acq.Stimulation & key, 'exp_type'), 'AcuteGratingExperiment')
    d = diff(macSwapTimes);
    periodMac = mean(d(d < 0.025));
    periodDiode = median(diff(diodeSwapTimes(1 : 100)));
    first = round(diff(macSwapTimes(1 : 2)) / periodMac) * periodDiode;
    k = sum(diff(diodeSwapTimes(end - 4 : end)) > 25);
    diodeSwapTimes = [diodeSwapTimes(1) - first; diodeSwapTimes(1 : end - k)];
    N = 50;
else
    N = 10;
end
assert(numel(macSwapTimes) == numel(diodeSwapTimes), 'Not all swaps found in photodiode signal. Chaos!!!')

% compute regression iteratively
period = 1000 / 60;  % 60 Hz
macPar = regress(diodeSwapTimes(1 : N), [ones(N, 1), macSwapTimes(1 : N)]);
offset = round((diodeSwapTimes - macSwapTimes * macPar(2) - macPar(1)) / period);
drop = find(offset, 1);
while N < numel(diodeSwapTimes) || ~isempty(drop)
    if drop < 2 * N
        n = [0 cumsum(arrayfun(@(x) numel(x.swapTimes), stim.params.trials))];
        n = n - nskip;   % couple of swaps are skipped at the beginning of some stimulus types
        trial = find(drop < n, 1) - 1;
        frame = drop - n(trial);
        
        % adjust timestamps in trial where missed frame occurred
        shift = (period * offset(drop)) / macPar(2);
        ts = stim.params.trials(trial).swapTimes;
        ts(frame : end) = ts(frame : end) + shift;
        stim.params.trials(trial).swapTimes = ts;
        et = stim.events(trial).times;
        et(et >= ts(frame)) = et(et >= ts(frame)) + shift;
        stim.events(trial).times = et;
        
        % adjust timestamps in remaining trials
        for i = trial + 1 : length(stim.events)
            stim.events(i).times = stim.events(i).times + shift;
            stim.params.trials(i).swapTimes = stim.params.trials(i).swapTimes + shift;
        end
        
        % insert into database
        tuple = key;
        tuple.trial_num = trial;
        tuple.frame_num = frame;
        tuple.shift = offset(drop);
        inserti(acq.FrameDrops, tuple)
        
        macSwapTimes = getMacSwapTimes(stim);
    end
    
    N = min(2 * N, numel(diodeSwapTimes));
    macPar = regress(diodeSwapTimes(1 : N), [ones(N, 1), macSwapTimes(1 : N)]);
    offset = round((diodeSwapTimes - macSwapTimes * macPar(2) - macPar(1)) / period);
    drop = find(offset, 1);
end

% convert times in stim file
stimDiode = convertStimTimes(stim, macPar, [0 1]);
stimDiode.synchronized = 'diode';

% plot residuals
maxPhotodiodeErr = 3;  % RMS in ms after correction
figure
res = getMacSwapTimes(stimDiode) - diodeSwapTimes(:);
plot(diodeSwapTimes, res, '.k');
drawnow
shg
rms = sqrt(mean(res.^2));
assert(rms < maxPhotodiodeErr, 'Residuals too large after synchronization to photodiode!');
fprintf('Residuals on photodiode regression had a range of %g and an RMS of %g ms\n', range(res), rms);

offset = -1; % irrelevant for these recordings


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

% preprocessing filter
[b, a] = butter(params.filterOrder, params.refresh / Fs * 2, 'low');

% determine threshold (using a chunk of data in the middle)
first = fix(length(br) / 2);
last = first + params.chunkSize;
x = br(first+1:last, 1);
y = filtfilt(b, a, x);
switch fetch1(acq.Stimulation & key, 'exp_type')
    case {'AcuteGratingExperiment', 'SquareMappingExperiment'}
        m = median(y);
        startSample = Fs * params.cropStart; 
    case 'FlashingBar'
        m = 2 * median(y);
        startSample = 0;
end

% process photodiode signal in chunks to detect buffer swaps
totalSamples = length(br) - startSample;
nChunks = ceil(totalSamples / params.chunkSize);

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


function [t, nskip] = getMacSwapTimes(stim)
% Deal with some details of how photodiode signal is handled in acute
% experiments. Not all frames are registered because Wangchen changed the
% photodiode timer sucher that it changes polarity only during the stimulus
% loop.

t = cat(1, stim.params.trials.swapTimes);
if ~strcmp(stim.params.constants.expType, 'AcuteGratingExperiment')
    nskip = 2;
    t = t(nskip + 1 : end - 1);
else
    nskip = 0;
end

