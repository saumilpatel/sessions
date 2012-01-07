
function success = synchronizeStim(sDb,ephys,stim,varargin)
% Synchronize a stimulation file to an ephys recording
params.maxErr = 100;
params.oldFile = false;
params.maxPhotodiodeErr = 0.100;  % 100 us err allowed
params.minNegTime = -100;  % 100 ms timing error
params.maxRoundtrip = 4;
params = parseVarArgs(params, varargin{:});


%% Check synchronization
[stimFileName stimFile] = getStimFile(sessions.Stimulation(stim));
stimFileName = stimFileName{1};

% Straightforward sync now
% load up the sync times
sy = [stimFile.params.trials.sync];
s = [sy.start];
e = [sy.end];
r = [sy.response];
mid = (s + e) / 2; % These are the mac times
mid = mid / 1000;  % for whatever reason sync times are consistent in ms

% to convert from mac time to pc counter use p(2)*mac + p(1)
i = find((e-s) < params.maxRoundtrip);
assert(mean((e-s) < params.maxRoundtrip) > 0.8, 'Excluding too many network sync packets');
p = robustfit(mid(i),r(i));

% get the "zero" time of the counter that was used for network sync relative to
% session time 
t0 = getHardwareStartTime(sDb, fetch(sessions.BehaviorTraces .* sessions.Stimulation(stim)));
stimFileOut = convertStimTimes(stimFile, p, [0; 1]);
stimFileOut = convertStimTimes(stimFileOut, [t0; 1], [t0; 1]);
stimFileOut.synchronized = 'network';

% Get photodiode swap times
br = getEphysFile(sDb, ephys,'Photodiode');
[peakTimes peakAmps] = detectPhotodiodePeaks(br,'threshold',0.04);
close(br);

% detect swaps
da = abs(diff(peakAmps));
[mu, v] = MoG1(da(:), 2, 'cycles', 50, 'mu', [0 median(da)]);
sd = sqrt(v);
swaps = find(da > min(15*sd(1),mean(mu))) + 1;
diodeSwapTimes = peakTimes(swaps)';

% throw out falsely detected swaps
% swap times recorded on the Mac
macSwapTimes = cat(1,stimFileOut.params.trials.swapTimes);
idx = find(diodeSwapTimes >= macSwapTimes(1) & diodeSwapTimes <= macSwapTimes(end));
%[macSwapTimes diodeSwapTimes] = matchCloseEvents(macSwapTimes, diodeSwapTimes(idx));
[macSwapTimes diodeSwapTimes] = matchEvents(macSwapTimes, diodeSwapTimes(idx));

% exact correction using robust linear regression
macPar = robustfit(macSwapTimes, diodeSwapTimes);
assert(abs(macPar(2) - 1) < 1e-5  & (abs(macPar(1)) < 5), 'Regression between behavior clock and photodiode clock outside system tolerances');

% convert times in stim file
stimFileDiode = convertStimTimes(stimFileOut, macPar, [0 1]);
stimFileDiode.synchronized = 'diode';

[a b c] = fileparts(stimFileName);
stim = stimFileDiode;
save(fullfile(a,[b 'Synced' c]),'stim');

% plot residuals
figure;
macSwapTimes = cat(1,stimFileDiode.params.trials.swapTimes);
diodeSwapTimes = peakTimes(swaps)';
idx = find(diodeSwapTimes >= macSwapTimes(1) & diodeSwapTimes <= macSwapTimes(end));
[macSwapTimes diodeSwapTimes] = matchEvents(macSwapTimes, diodeSwapTimes(idx));
res = macSwapTimes-diodeSwapTimes;
plot(diodeSwapTimes,res,'.');
assert(std(res) < params.maxPhotodiodeErr);

disp(sprintf('Offset between behavior timer and photodiode timer was %g ms and the relative rate was %0.8g', macPar(1), macPar(2)));
disp(sprintf('Residuals on photodiode regression had a range of %g and std of %g ms', range(res), std(res)));

success = true;
