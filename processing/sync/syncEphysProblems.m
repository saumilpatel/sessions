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

% detect swaps
da = abs(diff(peakAmps));
[mu, v] = MoG1(da(:), 2, 'cycles', 50, 'mu', [0 median(da)]);
sd = sqrt(v);
swaps = find(da > min(15 * sd(1), mean(mu))) + 1;
diodeSwapTimes = peakTimes(swaps);

% determine chunks of data to use (t ms but at least n points)
N = min(numel(diodeSwapTimes), numel(macSwapTimes));
t = 20 * 60 * 1000; % length of segments (ms)
n = 1000;           % unless we have less than 1000 points
chunks = 0;
while chunks(end) < N
    ndx = chunks(end) + find(macSwapTimes(chunks(end)+1:end) > macSwapTimes(chunks(end)+1) + t, 1, 'first');
    if isempty(ndx) || ndx > N - n
        chunks(end+1) = N; %#ok
    else
        chunks(end+1) = max(chunks(end) + n, ndx);  %#ok
    end
end
chunks(end) = max(numel(macSwapTimes), numel(diodeSwapTimes));
nChunks = numel(chunks) - 1;
macSwapTimesMatched = cell(1, nChunks);
diodeSwapTimesMatched = cell(1, nChunks);

% initial rough estimate of regression parameters
ndx = chunks(1)+1:chunks(2);
[macPar, macSwapTimesMatched{1}, diodeSwapTimesMatched{1}] ...
    = estimateRegPar(macSwapTimes(ndx), diodeSwapTimes(ndx));

% update parameters in chunks
macPar = [macPar, zeros(2, nChunks - 1)];
for i = 2:nChunks
    macNdx = chunks(i)+1:min(numel(macSwapTimes), chunks(i+1));
    diodeNdx = chunks(i)+1:min(numel(diodeSwapTimes), chunks(i+1));
    [macPar(:,i), macSwapTimesMatched{i}, diodeSwapTimesMatched{i}] ...
        = updateRegPar(macSwapTimes(macNdx), diodeSwapTimes(diodeNdx), macPar(:,i-1));
end

% convert times in stim file
stimDiode = convertStimTimesPiecewise(stim, macPar, macSwapTimes([1 chunks(2:end-1) end]));
stimDiode.synchronized = 'diode';

% plot residuals
figure
N = sum(cellfun(@numel, macSwapTimesMatched));
macSwapTimes = cat(1, stimDiode.params.trials.swapTimes);
diodeSwapTimes = peakTimes(swaps)';
[macSwapTimes, diodeSwapTimes] = matchTimes(macSwapTimes, diodeSwapTimes, [0 1]);
assert(numel(macSwapTimes) >= N, 'Error during timestamp conversion. Number of timestamps don''t match!')
res = macSwapTimes(:) - diodeSwapTimes(:);
plot(diodeSwapTimes, res, '.k');
rms = sqrt(mean(res.^2));
assert(rms < params.maxPhotodiodeErr, 'Residuals too large after synchronization to photodiode!');

fprintf('Relative rate between behavior timer and photodiode timer was %0.8g\n', macPar(2));
fprintf('Residuals on photodiode regression had a range of %g and an RMS of %g ms\n', range(res), rms);

offset = 3.5;  % hardcoded since there is no trivial way of getting it here


function [b, x, y] = estimateRegPar(x, y)

% rough estimate of gain
gains = 1 + 1e-6 * (1:30);
Fs = 10;        % kHz
k = 200;        % max offset (samples) in each direction
c = zeros(2 * k + 1, 1);
s = zeros(1, numel(gains));
for j = 1 : numel(gains)
    gain = gains(j);
    for i = -k:k
        c(i + k + 1) = isectq(round(x * gain * Fs + i), round(y * Fs));
    end
    s(j) = skewness(c);
end
[~, maxj] = max(s);
gain = gains(maxj);

% rough estimate of offset
smooth = 10;
for i = -k:k
    c(i + k + 1) = isectq(round(x * gain * Fs + i), round(y * Fs));
end
win = gausswin(2 * smooth + 1); win = win / sum(win);
c = conv2(c, win, 'same');
[~, peak] = max(c);
offsets = (-k:k) / Fs;
n = smooth + Fs;
ndx = peak + (-n:n);
offset = offsets(ndx) * c(ndx) / sum(c(ndx));

% find matches and do accurate regression
[b, x, y] = updateRegPar(x, y, [offset gain]);




function [b, x, y] = updateRegPar(x, y, b)
% Update regression parameters based on a good guess

[x, y] = matchTimes(x, y, b);
b = regress(y, [ones(numel(x), 1), x]);


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


function [x, y] = matchTimes(x, y, b)
% find matching pairs in x and y (match = within 1 ms)

i = 1;
while i <= min(numel(x), numel(y))
    if x(i) * b(2) + b(1) < y(i) - 1
        x(i) = [];
    elseif x(i) * b(2) + b(1) > y(i) + 1
        y(i) = [];
    else
        i = i + 1;
    end
end
y(i:end) = [];
x(i:end) = [];

