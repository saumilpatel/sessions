function [peakTimes, peakAmps, peakSamples] = detectPhotodiodePeaks(br, varargin)
% Detect peaks in photodiode signal.
%   [peakTimes, peakAmps] = detectPhotodiodePeaks(x) detects all peaks and
%   their amplitudes in the photodiode signal x.
%
% Last update: AE 2011-04-14
% Initial: AE 2008-01-16

params.refresh = 99.58;
params.threshold = 50;
params.peakDetectTol = 0.01;
params.peakSamples = 5;
params.nPeaks = 10;
params.sigma = 0.05;
params.chunkSize = 1000000;
params.tstart = [];
params.tend = [];
params = parseVarArgs(params, varargin{:});

Fs = getSamplingRate(br);

% preprocessing
win = makePhotodiodeFilter(Fs, params.refresh, params.nPeaks, params.sigma);


% sample range
if(~isempty(params.tstart))
    if(params.tstart < br(1,'t'))
        startSample = 1;
    else
        startSample = getSampleIndex(br, params.tstart);
    end
    assert(abs(br(startSample,'t') - params.tstart) < 60*1000, 'Start of file off by more than a minute');
else
    startSample = 1;
end

if(~isempty(params.tend)) 
    if(params.tend > br(end,'t'))
        endSample = size(br,1)
    else
        endSample = getSampleIndex(br, params.tend);
    end
    assert(abs(br(endSample,'t') - params.tend) < 60*1000, 'End of file off by more than a minute');
else
    endSample = size(br,1);
end

totalSamples = endSample - startSample + 1;

% determine refresh rate
ndx = (startSample + endSample) / 2 + (1:10*Fs); % 10 secs in the middle
params.refresh = getRefreshByDiode(br(ndx, 1), Fs, params.refresh);

% process photodiode signal in chunks to detect buffer swaps
nChunks = ceil(totalSamples / params.chunkSize);
diodeSwapTimes = [];
overlap = ceil((params.nPeaks + 1) * Fs / params.refresh);

peakAmps = [];
peakSamples = [];

disp(sprintf('Detecting photodiode peaks %u chunks', nChunks));
for j = 1:nChunks
    fprintf('.');
    if  mod(j,round((nChunks / 20))) == 0
        disp(['Photodiode detection: ' num2str(round(j * 100 / nChunks)) '%']);
    end

    % make chunks slightly overlapping to avoid detecting peaks falling on
    % the separation bewteen two chunks twice. We wouldn't be able to
    % detect a buffer swap in that case
    b = startSample + (j - 1) * params.chunkSize;
    e = min(startSample + j * params.chunkSize + overlap, endSample);

    x = br(b:e,1);
    y = conv(x, win); 

    % filter has zero phase so no compensation necessary at the beginning. It's
    % acausal, though, so we need to crop off at the end
    y = y(1:numel(x)-numel(win)+1);
    
    % Detect peaks above threshold
    yp = find(y(1:end-2) < y(2:end-1) & y(2:end-1) > y(3:end) & y(2:end-1) > params.threshold);
    
    % make sure the parameters are robust
    h = hist(diff(yp), [0.8, 1, 1.5] * Fs / params.refresh);
    if h(3) / h(2) > params.peakDetectTol
        error('Photodiode:detectPeaks', ...
            ['%.3f%% of the peaks missed. Increase params.nPeaks (currently ', ...
            '%d) and check your data if this doesn''t help!'], ...
            h(3) / h(2) * 100, params.nPeaks)
    elseif h(1) / h(2) > params.peakDetectTol
        error('Photodiode:detectPeaks', ...
            ['%.3f%% false positives detected. Try increasing params.nPeaks ' ...
            '(currently %d) and check your data if this doesn''t help!'], ...
            h(1) / h(2) * 100, params.nPeaks)
    end
    
    if isempty(yp)
        continue
    end
    
    % Find maxima around estimated peak location
    % Because we want to detect changes in peak amplitude we have to do this on
    % the raw signal. Finding the peak on the raw signal will probably
    % introduce some noise but this should be (a) small and (b) average out in
    % the synchronization procedure.
    p = params.peakSamples;
    peakRegion = x(bsxfun(@plus, yp, -p:p));
    [amps, ndx] = max(peakRegion, [], 2);
    
    peakAmps = [peakAmps; amps];                     %#ok<AGROW>
    peakSamples = [peakSamples; yp + ndx - p - 1 + b - 1];   %#ok<AGROW>
end

peakTimes = br(peakSamples,'t');
