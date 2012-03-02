% function [flips,flipSign,qratio] = detectLcdPhotodiodeFlips( x, Fs, flipFreq )
% detect flips in a photodiode signal.
%
% INPUTS:
% x is the input signal
% Fs is the sampling frequency of x
% flipFreq is typically 30 Hz.  (60 flips per second). 
%
% OUTPUTS:
% flips contains the indices of flips in x.
% flipSign is -1 or 1 for each flip 
% qratio is the ratio of the first percentile of flip amplitude to the 99th
% percentile of non-flip amplitude. For good photodiode signal this value should be
% significanly higher than 1, e.g. >10 or even >50. 
%
% Dimitri Yatsenko 2010-09-01

function [flips,flipSign,qratio] = detectLcdPhotodiodeFlips( x, Fs, flipFreq )
T = Fs/flipFreq;  % period of oscillation measured in samples
% filter flips
n = floor(T/2);
k = hamming(n);
k = [k;0;-k]/sum(k);
x = fftfilt(k,[double(x);zeros(n,1)]);
x = x(n+1:end);
x([1:n end+[-n+1:0]])=0;
flipSign = sign(x);
x = abs(x);
% select flips
flips = spaced_max(x,0.45*T);
thresh = 0.3*quantile( x(flips), 0.999);
idx = x(flips)>thresh;
qratio = quantile(x(flips(idx)),0.01)/quantile(x(flips(~idx)),0.99);
flips = flips(idx)';
flipSign = flipSign(flips);













function [peakTimes, peakAmps] = detectPhotodiodePeaks(br, tstart, tend, varargin)
% Detect peaks in photodiode signal.
%   [peakTimes, peakAmps] = detectPhotodiodePeaks(br, tstart, tend) detects
%   all peaks and their amplitudes in the photodiode signal. br is a
%   baseReader with only the photodiode channel opened.
%
% Last update: AE 2011-10-25
% Initial: AE 2008-01-16

params.refresh = 99.58;
params.peakDetectTol = 0.01;
params.peakSamples = 5;
params.nPeaks = 5;
params.sigma = 0.05;
params.chunkSize = 1e6;
params = parseVarArgs(params, varargin{:});

Fs = getSamplingRate(br);

% preprocessing
win = makePhotodiodeFilter(Fs, params.refresh, params.nPeaks, params.sigma);

% sample range
startSample = getSampleIndex(br, tstart);
endSample = getSampleIndex(br, tend);
totalSamples = endSample - startSample + 1;

% determine refresh rate
ndx = (startSample + endSample) / 2 + (1:10*Fs); % 10 secs in the middle
params.refresh = getRefreshByDiode(br(ndx, 1), Fs, params.refresh);

% process photodiode signal in chunks to detect buffer swaps
nChunks = ceil(totalSamples / params.chunkSize);
overlap = ceil((params.nPeaks + 1) * Fs / params.refresh);

peakAmps = [];
peakTimes = [];

fprintf('Detecting photodiode peaks (%u chunks)\n', nChunks);
for j = 1:nChunks

    % make chunks slightly overlapping to avoid detecting peaks falling on
    % the separation between two chunks twice. We wouldn't be able to
    % detect a buffer swap in that case
    b = startSample + (j - 1) * params.chunkSize;
    e = min(startSample + j * params.chunkSize + overlap, endSample);

    x = br(b:e,1);
    y = conv(x, win); 

    % filter has zero phase delay so no compensation necessary at the
    % beginning. It's acausal, though, so we need to crop off at the end
    y = y(1:numel(x)-numel(win)+1);
    
    % Detect peaks
    yp = find(y(1:end-2) < y(2:end-1) & y(2:end-1) > y(3:end) & y(2:end-1) > prctile(y, 99) / 10);
    
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
    
    progress(j, nChunks, 20)

    if isempty(yp)
        continue
    end
    
    % Find maxima around estimated peak location
    % Because we want to detect changes in peak amplitude we have to do
    % this on the raw signal. Finding the peak on the raw signal will
    % probably introduce some noise but this should be (a) small and (b)
    % average out in the synchronization procedure.
    p = params.peakSamples;
    yp(yp <= params.peakSamples | yp > length(x) - params.peakSamples) = [];
    peakRegion = x(bsxfun(@plus, yp, -p:p));
    [amps, ndx] = max(peakRegion, [], 2);
    
    peakAmps = [peakAmps; amps];                     %#ok<AGROW>
    peakSamples = yp + ndx - p - 1 + b - 1;
    peakTimes = [peakTimes; reshape(br(peakSamples,'t'), [], 1)];    %#ok<AGROW>
end
