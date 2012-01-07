function stim = syncStimDiode(stim, br, tstart, tend, varargin)
% Synchronize stim structure to common reference clock using photodiode.
%
% AE 2011-04-14

params.refresh = 100;
params.nPeaks = 10;
params = parseVarArgs(params, varargin{:});

% calculate mapping from LabView timestamps to the global reference clock

% TODO
behPar = 1;


% swap times recorded on the Mac
macSwapTimes = cat(1,stim.params.trials.swapTimes);

% raw photodiode signal
br = baseReader(fileName, 'photodiode');
Fs = getSamplingRate(br);

% sample range
startSample = getSampleIndex(br, tstart);
endSample = getSampleIndex(br, tend);
totalSamples = endSample - startSample + 1;

% determine refresh rate
ndx = (startSample + endSample) / 2 + (1:10*Fs); % 10 secs in the middle
params.refresh = getRefreshByDiode(br(ndx, 1), Fs, params.refresh);

% process photodiode signal in chunks to detect buffer swaps
nChunks = ceil(totalSamples / params.chunkSize);
diodeSwapTimes = [];
overlap = ceil((params.nPeaks + 1) * Fs / params.refresh);
for j = 1:nChunks
    % make chunks slightly overlapping to avoid detecting peaks falling on
    % the separation bewteen two chunks twice. We wouldn't be able to
    % detect a buffer swap in that case
    b = startSample + (j - 1) * params.chunkSize;
    e = min(startSample + j * params.chunkSize + overlap, endSample);
    
    % detect peaks in photodiode signal
    [peakTimes, peakAmps] = detectPhotodiodePeaks(br(b:e), varargin{:}, 'refresh', params.refresh);
    
    % detect swaps
    da = abs(diff(peakAmps));
    [mu, v] = MoG1(da(:), 2, 'cycles', 50, 'mu', [0 median(da)]);
    sd = sqrt(v);
    swaps = find(da > min(15*sd(1),mean(mu))) + 1;
    diodeSwapTimes = [diodeSwapTimes; peakTimes(swaps)];    %#ok<AGROW>
end

% get rid of doubles due to overlapping segments
diodeSwapTimes = unique(diodeSwapTimes);

% throw out falsely detected swaps
[macSwapTimes, diodeSwapTimes] = matchEvents(macSwapTimes, diodeSwapTimes, varargin{:});

% exact correction using robust linear regression
macPar = robustfit(macSwapTimes, diodeSwapTimes);

% convert times in stim file
stim = convertStimTimes(stim, macPar, behPar);
stim.synchronized = 'diode';

% throw warning if recorded segment does not fully cover the experiment
if stim.params.constants.startTime < tstart || stim.params.constants.endTime > tend
    warning('syncStimDiode:partialRecording', 'Not the entire behavior session was recorded!')
end
