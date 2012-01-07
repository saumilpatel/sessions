
function success = synchronizeStim(sDb,ephys,stim,varargin)
% Synchronize a stimulation file to an ephys recording
params.maxErr = 100;
params.oldFile = false;
params.maxPhotodiodeErr = 0.100;  % 100 us err allowed
params.minNegTime = -100;  % 100 ms timing error
params.maxRoundtrip = 3;
params = parseVarArgs(params, varargin{:});


%% Check synchronization
[stimFileName stimFile] = getStimFile(sDb,stim);
stimFileName = stimFileName{1};

% Some session event sites were wrong
stimFile.eventSites = fixSites(stimFile.eventTypes);

ts = fetch(SessionTimestamps .* ...
    TimestampSources('source="Stimulation"') .* Stimulation(stim), ...
    'timestamper_time','count');
counter_time = counterToTime(sDb, ts);
system_time = [ts.timestamper_time];

sy = [stimFile.params.trials.sync];
s = [sy.start];
e = [sy.end];
r = [sy.response]; % pc times (in ms)
mid = (s + e) / 2; % These are the mac times

% convert all pc times over to the hardware clock
r = interp1(system_time - stim.stim_start_time, counter_time, r);
i = find((e-s) < 3);
% mac times in file are in seconds but syncs were in ms
p = robustfit(mid(i) / 1000,r(i));

% use this regression to convert the mac times to counter times (both
% clocks should be running at a fixed rate)
stimFileOut = convertStimTimes(stimFile, p, [0 1]);
stimFileOut.synchronized = 'network';

% Move all the pc system times to counter times (since counter drifts cannot use regression)
pcEvents = find(stimFileOut.eventSites == 1);
for i = 1:length(stimFileOut.events)
    j = find(ismember(stimFileOut.events(i).types, pcEvents) & stimFileOut.events(i).times ~= 0);
    pcTimes = stimFileOut.events(i).times(j);
    r = interp1(system_time, counter_time, pcTimes*1000);  % times are in seconds in old files, should be ms
    stimFileOut.events(i).times(j) = r;
    
    % Move the ones that were not set to NaN
    j = find(stimFileOut.events(i).times == 0);
    stimFileOut.events(i).times(j) = NaN;
end

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
assert(abs(macPar(2) - 1) < 1e-2  & (abs(macPar(1)) < 1000), 'Regression between behavior clock and photodiode clock outside system tolerances');

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
