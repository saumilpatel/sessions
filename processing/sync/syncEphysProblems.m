function [stimDiode, rms, offset] = syncEphysProblems(stim, key)
% Synchronize a stimulation file to an ephys recording
% AE 2011-10-25

params.maxErr = 100;
params.oldFile = false;
params.maxPhotodiodeErr = 0.250;  % 250 us err allowed
params.maxBehDiodeErr = [1e-5 5]; % [slope offset] in ms
params.diodeThreshold = 0.04;
params.minNegTime = -100;  % 100 ms timing error

% Get photodiode swap times
tstart = stim.params.trials(1).swapTimes(1) - 500;
tend = stim.params.trials(end).swapTimes(end) + 500;
br = getFile(acq.Ephys(key), 'Photodiode');
assert(br(1, 't') ~= 0, 'Update t0 in ephys file first!')
[peakTimes, peakAmps] = detectPhotodiodePeaks(br, tstart, tend);
close(br);

% swap times recorded on the Mac
macSwapTimes = cat(1, stim.params.trials.swapTimes);
t0 = macSwapTimes(1);
macSwapTimes = macSwapTimes - t0;

% detect swaps
da = abs(diff(peakAmps));
[mu, v] = MoG1(da(:), 2, 'cycles', 50, 'mu', [0 median(da)]);
sd = sqrt(v);
swaps = find(da > min(15 * sd(1), mean(mu))) + 1;
diodeSwapTimes = peakTimes(swaps)' - t0;

% Find optimal gain by line search
gains = 1 + 1e-06 * (1:40);
Fs = 10;        % kHz
k = 200;        % max offset (samples) in each direction
smooth = 10;    % smoothing window for finding the peak (half-width);
c = zeros(2 * k + 1, 1);
s = zeros(1, numel(gains));
for j = 1 : numel(gains)
    gain = gains(j);
    for i = -k:k
        c(i + k + 1) = isectq(round(macSwapTimes * gain * Fs + i), round(diodeSwapTimes * Fs));
    end
    s(j) = skewness(c);
end
[maxs, maxj] = max(s);
assert(maxs > 2, 'Could not determine correct clock rate!')

% Find optimal offset using cross-correlation. Treat each swaptime as a
% delta peak. We can do this at relatively high sampling rate using sparse
% arithmetic and then smooth the result to account for jitter in the
% swaptimes
gain = gains(maxj);
macSwapTimes = macSwapTimes * gain;
for i = -k:k
    c(i + k + 1) = isectq(round(macSwapTimes * Fs + i), round(diodeSwapTimes * Fs));
end
win = gausswin(2 * smooth + 1); win = win / sum(win);
c = conv2(c, win, 'same');
[~, peak] = max(c);
offsets = (-k:k) / Fs;
n = smooth + Fs;
ndx = peak + (-n:n);
offset = offsets(ndx) * c(ndx) / sum(c(ndx));

% throw out swaps that don't have matches within one ms
[macSwapTimes, diodeSwapTimes] = matchTimes(macSwapTimes, diodeSwapTimes, offset);
N = numel(macSwapTimes);

% bring times back on their original clocks if they were manually adjusted
macSwapTimes = macSwapTimes / gain + t0;
diodeSwapTimes = diodeSwapTimes + t0;

% exact correction using robust linear regression (undo manual gain
% correction first)
% macPar = myrobustfit(macSwapTimes / gain, diodeSwapTimes);
macPar = regress(diodeSwapTimes', [ones(N, 1), macSwapTimes]);
assert(abs(macPar(2) - gain) < params.maxBehDiodeErr(1) && abs(offset) < params.maxBehDiodeErr(2), 'Regression between behavior clock and photodiode clock outside system tolerances');

% convert times in stim file
stimDiode = convertStimTimes(stim, macPar, [0 1]);
stimDiode.synchronized = 'diode';

% plot residuals
figure
macSwapTimes = cat(1, stimDiode.params.trials.swapTimes);
diodeSwapTimes = peakTimes(swaps)';
[macSwapTimes, diodeSwapTimes] = matchTimes(macSwapTimes, diodeSwapTimes, 0);
assert(N == numel(macSwapTimes), 'Error during timestamp conversion. Number of timestamps don''t match!')
res = macSwapTimes(:) - diodeSwapTimes(:);
plot(diodeSwapTimes, res, '.k');
rms = sqrt(mean(res.^2));
assert(rms < params.maxPhotodiodeErr, 'Residuals too large after synchronization to photodiode!');

fprintf('Offset between behavior timer and photodiode timer was %g ms and the relative rate was %0.8g\n', offset, macPar(2));
fprintf('Residuals on photodiode regression had a range of %g and an RMS of %g ms\n', range(res), rms);


function n = isectq(a, b)
% number of intersecting points in a and b

na = numel(a);
nb = numel(b);
ia = 1;
ib = 1;
n = 0;
while ia <= na && ib <= nb
    if a(ia) == b(ib)
        n = n + 1;
        ia = ia + 1;
        ib = ib + 1;
    elseif a(ia) < b(ib)
        ia = ia + 1;
    elseif a(ia) > b(ib)
        ib = ib + 1;
    end
end




function [macSwapTimes, diodeSwapTimes] = matchTimes(macSwapTimes, diodeSwapTimes, offset)

i = 1;
while i <= min(numel(macSwapTimes), numel(diodeSwapTimes))
    if macSwapTimes(i) + offset < diodeSwapTimes(i) - 1
        macSwapTimes(i) = [];
    elseif macSwapTimes(i) + offset > diodeSwapTimes(i) + 1
        diodeSwapTimes(i) = [];
    else
        i = i + 1;
    end
end
diodeSwapTimes(i:end) = [];
macSwapTimes(i:end) = [];



