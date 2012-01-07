function output = sanityCheck(sDb, clus_set_stim)
% Sanity check a cluster set for synchronization.
%
% sanityCheck(sDb, clus_set_stim)
%
% Check the synchronziation for both the behavioral traces and the
% electrophysiological traces.
%
% JC 2011-08-11

% TODO: Check the relationship between the hardware timestamps from behavior
% and the entries in the stimulation file

stim = getEntries(sDb, clus_set_stim, 'stimulation');
beh = getBehaviorByStimulation(sDb, stim);
ephys = getEntries(sDb, clus_set_stim, 'ephys');

[stimFileName stimFile] = getStimFile(sDb, stim, 'Synced');
brBeh = getBehFile(sDb, beh);
brEphys = getEphysFile(sDb, ephys);

behT0 = getHardwareStartTime(sDb, beh);
ephysT0 = getHardwareStartTime(sDb, ephys);

if(brEphys(1,'t') ~= ephysT0) 
    warning('Behavior file t0 not set'); %#ok<*WNTAG>
    brEphys = updateT0(brEphys, ephysT0);
end

if(brBeh(1,'t') ~= behT0) 
    warning('Behavior file t0 not set');
    brBeh = updateT0(brBeh, behT0);
end

close(brBeh);
close(brEphys);

% Reopen with correct channel
brBeh = getBehFile(sDb, beh,'Photodiode');
brEphys = getEphysFile(sDb, ephys,'Photodiode');

% Get all the swap times
macSwapTimes = cat(1,stimFile.params.trials.swapTimes);

% Check the error on the swap times versus the electrophysiology
[peakEphysTimes peakEphysAmps] = detectPhotodiodePeaks(brEphys,'threshold',0.04, 'tstart', macSwapTimes(1),'tend',macSwapTimes(end));
diodeSwapTimes = getSwapTimes(peakEphysTimes, peakEphysAmps);
output.resEphys = getErr(macSwapTimes,diodeSwapTimes);

% At 2khz unfortunately we can't detect swaps with this diode, but we can
% make sure the peaks are about the right time
[peakBehTimes peakBehAmps] = detectPhotodiodePeaks(brBeh,'threshold',1, 'tstart', macSwapTimes(1),'tend',macSwapTimes(end));

% Compare the times of all peaks between behavior and ephys
% Start and end times should be very closely aligned if hardware times
% correct
output.resEphysBeh = getErr(peakBehTimes,peakEphysTimes);

function swapTimes = getSwapTimes(times, amps)
da = abs(diff(amps));
[mu, v] = MoG1(da(:), 2, 'cycles', 50, 'mu', [0 median(da)]);
sd = sqrt(v);
swaps = find(da > min(15*sd(1),mean(mu))) + 1;
swapTimes = times(swaps)';

function res = getErr(t1, t2)
idx = find(t2 >= t1(1) & t2 <= t1(end));
[s1 s2] = matchEvents(t1, t2(idx));
res = s1-s2;
