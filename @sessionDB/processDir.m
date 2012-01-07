function processDir(sDb, dirName, varargin)
% processDir(sDb, dirName, varargin)
%
% Current run from a stimulation directory and only handles one stim at a
% time.  Needs to be refactored to run on a recording directory and give
% all the stimulation sessions that are valid.
%
% JC 2011-08-04

params.maxErr = 100;
params.oldFile = false;
params.maxPhotodiodeErr = 0.100;  % 100 us err allowed
params.minNegTime = -100;  % 100 ms timing error
params = parseVarArgs(params, varargin{:});

%% Find matching entries in session database
% Get the stim_path and exp_type from dirName
dirName = getGlobalPath(dirName);
fileName = dir(getLocalPath([dirName '/*.mat']));
assert(length(fileName) == 1, 'This directory appears to already be processed');
dirName = strrep(dirName, '/stor01/stimulation', '/stimulation');
[foo expType] = fileparts(fileName.name);

% File stimulation table entry
dat = mym('SELECT * FROM stimulation WHERE stim_path="{S}" AND exp_type="{S}"', dirName, expType);
stim = parseMym(sDb, dat);
assert(length(stim) == 1, 'Either multiple session entries found or none found');
stim.table = 'stimulation';

disp('Found stimulation session: ')
stim

% Find any ephys files that match
ephys = getMatches(sDb, 'ephys', setfield(stim,'table','sessions'), ...
    sprintf('ephys_start_time < %16.16g AND ephys_stop_time > %16.16g', stim.stim_start_time + 120000, stim.stim_stop_time - 120000));
assert(length(ephys) <= 1, 'Two matching ephys found.  This should not happen');
if(length(ephys) ~= 1)
    ephys = getMatches(sDb, 'ephys', setfield(stim,'table','sessions'));
    if(length(ephys) < 1)
        error('No ephys recorded with this session')
    else
        %error('An ephys session was found for this session but none with sufficiently overlapping time');
    end
end
       
%% Check synchronization
[stimFileName stimFile] = getStimFile(sDb,stim);
stimFileName = stimFileName{1};

% Get behavior entry
beh = getBehaviorByStimulation(sDb,stim);

if params.oldFile  % Before July 17th
    % Some session event sites were wrong
    stimFile.eventSites = fixSites(stimFile.eventTypes);

    ts = getSessionTimestamps(sDb,setfield(stim,'table','sessions'));
    system_time = [ts.timestamper_time];
    counter_time = [ts.counter_time];
    
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
else
    % Straightforward sync now
    % load up the sync times
    sy = [stimFile.params.trials.sync];
    s = [sy.start];
    e = [sy.end];
    r = [sy.response];
    mid = (s + e) / 2; % These are the mac times
    mid = mid / 1000;  % for whatever reason sync times are consistent in ms
        
    % to convert from mac time to pc counter use p(2)*mac + p(1)
    i = find((e-s) < 3);
    p = robustfit(mid(i),r(i));

    % TODO: get offset of behavior traces to get that timer offset
    t0 = getHardwareStartTime(sDb, beh);
    br = getBehFile(sDb,beh);
    br = updateT0(br, t0);
    close(br);
    
    stimFileOut = convertStimTimes(stimFile, p, [0; 1]);
    stimFileOut = convertStimTimes(stimFileOut, [t0; 1], [t0; 1]);
    stimFileOut.synchronized = 'network';
end

t = cat(2,stimFileOut.events.times);
assert(min(diff(t)) > -100, 'Found large negative step in event times.  Network synchronization failed');

br = getEphysFile(sDb, ephys(1),'Photodiode');
br = updateT0(br, getHardwareStartTime(sDb, ephys));
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
[macSwapTimes diodeSwapTimes] = matchEvents(macSwapTimes, diodeSwapTimes(idx));

% exact correction using robust linear regression
macPar = robustfit(macSwapTimes, diodeSwapTimes);
assert(abs(macPar(2) - 1) < 1e-5  & (macPar(1) < 5), 'Regression between behavior clock and photodiode clock outside system tolerances');


% convert times in stim file
stimFileDiode = convertStimTimes(stimFileOut, macPar, [0 1]);
stimFileDiode.synchronized = 'diode';

% plot residuals
macSwapTimes = cat(1,stimFileDiode.params.trials.swapTimes);
diodeSwapTimes = peakTimes(swaps)';
idx = find(diodeSwapTimes >= macSwapTimes(1) & diodeSwapTimes <= macSwapTimes(end));
[macSwapTimes diodeSwapTimes] = matchEvents(macSwapTimes, diodeSwapTimes(idx));
res = macSwapTimes-diodeSwapTimes;
plot(diodeSwapTimes,res,'.');
assert(std(res) < params.maxPhotodiodeErr);

disp(sprintf('Offset between behavior timer and photodiode timer was %g ms and the relative rate was %0.8g', macPar(1), macPar(2)));
disp(sprintf('Residuals on photodiode regression had a range of %g and std of %g ms', range(res), std(res)));

%% Cluster ephys
clusterSet(sDb, ephys, stim);

[a b c] = fileparts(stimFileName);
stim = stimFileDiode;
save(fullfile(a,[b 'Synced' c]),'stim');
