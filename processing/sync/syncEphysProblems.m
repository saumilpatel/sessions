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
diodeSwapTimes = peakTimes(swaps) - t0;

% determine chunks of data to use (t ms but at least n points)
N = numel(macSwapTimes);
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
nChunks = numel(chunks) - 1;
macSwapTimesMatched = cell(1, nChunks);
diodeSwapTimesMatched = cell(1, nChunks);

% initial estimate of regression parameters
macNdx = chunks(1)+1:chunks(2);
diodeNdx = chunks(1)+1:min(numel(diodeSwapTimes), chunks(2));
b = estimateRegPar(macSwapTimes(macNdx), diodeSwapTimes(diodeNdx));
offset = b(1);

% put timestamps back on session clock
macSwapTimes = macSwapTimes + t0;
diodeSwapTimes = diodeSwapTimes + t0;
b(1) = b(1) - (b(2) - 1) * t0;

% update parameters in chunks
macPar = [b, zeros(2, nChunks)];
for i = 1:nChunks
    macNdx = chunks(i)+1:chunks(i+1);
    t = (diodeSwapTimes - macPar(1,i)) / macPar(2,i);
    diodeNdx = t > macSwapTimes(macNdx(1)+1) - 1 & t < macSwapTimes(macNdx(end)) + 1;
    [macPar(:,i+1), macSwapTimesMatched{i}, diodeSwapTimesMatched{i}] ...
        = updateRegPar(macSwapTimes(macNdx), diodeSwapTimes(diodeNdx), macPar(:,i));
end

% convert times in stim file
stimDiode = convertStimTimesPiecewise(stim, macPar(:,2:end), offset, macSwapTimes([1 chunks(2:end-1) end]));
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

fprintf('Offset between behavior timer and photodiode timer was %.5g and the relative rate was  %0.8g\n', offset, macPar(2));
fprintf('Residuals on photodiode regression had a range of %g and an RMS of %g ms\n', range(res), rms);



function b = estimateRegPar(x, y)

% rough estimate of gain
gains = 1 + 1e-6 * (1:30);
Fs = 10;        % kHz
k = 200;        % max offset (samples) in each direction
c = zeros(2 * k + 1, 1);
m = zeros(1, numel(gains));
for j = 1 : numel(gains)
    gain = gains(j);
    for i = -k:k
        c(i + k + 1) = isectq(round(x * gain * Fs + i), round(y * Fs));
    end
    m(j) = max(c);
end
[~, maxj] = max(m);
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
b = updateRegPar(x, y, [offset gain]);




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

i = 1; j = 1;
keepx = true(size(x));
keepy = true(size(y));
while i <= numel(x) && j <= numel(y)
    if x(i) * b(2) + b(1) < y(j) - 1
        keepx(i) = false;
        i = i + 1;
    elseif x(i) * b(2) + b(1) > y(j) + 1
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
