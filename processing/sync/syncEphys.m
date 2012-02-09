function [stimDiode, rms, offset] = syncEphys(stim, key)
% Synchronize a stimulation file to an ephys recording
% AE 2011-10-25

params.oldFile = false;
params.maxPhotodiodeErr = 0.100;  % 100 us err allowed
params.behDiodeOffset = [3 4]; % [min max] in ms
params.behDiodeSlopeErr = 1e-7;   % max deviation from 1
params.diodeThreshold = 0.04;
params.minNegTime = -100;  % 100 ms timing error

if isempty(stim.events)
    stimDiode = stim;
    rms = -1;
    offset = 0;
    return  % empty file; nothing to do
end

assert(strcmp(stim.synchronized, 'network'), 'Run network sync first!')

% check date: in early sessions we had problems with the two hardware
% clocks (behavior, ephys) not being synched. This needs to be accounted
% for separately
% TODO: PUT CORRECT DATE WHEN THIS BUG WAS FIXED
if datenum(stim.params.constants.date, 'yyyy-mm-dd_HH-MM-SS') < datenum('2012/02/08 18:00:00')
    [stimDiode, rms, offset] = syncEphysProblems(stim, key);
    return
end

% Get photodiode swap times
tstart = stim.params.trials(1).swapTimes(1) - 500;
tend = stim.params.trials(end).swapTimes(end) + 500;
br = getFile(acq.Ephys(key), 'Photodiode');
assert(br(1, 't') ~= 0, 'Update t0 in ephys file first!')
[peakTimes, peakAmps] = detectPhotodiodePeaks(br, tstart, tend);
close(br);

% detect swaps
da = abs(diff(peakAmps));
[mu, v] = MoG1(da(:), 2, 'cycles', 50, 'mu', [0 median(da)]);
sd = sqrt(v);
swaps = find(da > min(15 * sd(1), mean(mu))) + 1;
diodeSwapTimes = peakTimes(swaps)';

% swap times recorded on the Mac
macSwapTimes = cat(1, stim.params.trials.swapTimes);

% Find optimal offset using cross-correlation. Treat each swaptime as a
% delta peak. We can do this at relatively high sampling rate using sparse
% arithmetic and then smooth the result to account for jitter in the
% swaptimes
Fs = 10;        % kHz
k = 200;        % max offset (samples) in each direction
smooth = 10;    % smoothing window for finding the peak (half-width);
c = zeros(2 * k + 1, 1);
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

% exact correction using robust linear regression (undo manual gain
% correction first)
% macPar = myrobustfit(macSwapTimes / params.gain, diodeSwapTimes);
macPar = regress(diodeSwapTimes', [ones(N, 1), macSwapTimes]);
assert(abs(macPar(2) - 1) < params.behDiodeSlopeErr ...
    && macPar(1) > params.behDiodeOffset(1) && macPar(1) < params.behDiodeOffset(2), ...
    'Regression between behavior clock and photodiode clock outside system tolerances');

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


function [x, y] = matchTimes(x, y, offset)

i = 1; j = 1;
keepx = true(size(x));
keepy = true(size(y));
while i <= numel(x) && j <= numel(y)
    if x(i) + offset < y(j) - 1
        keepx(i) = false;
        i = i + 1;
    elseif x(i) + offset > y(j) + 1
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
