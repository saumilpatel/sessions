function keys = checkStimStopTimes(sessKeys, resetStopTime)
% This function returns all the stim keys where the stop time is 
% inconsistent with the start time and duration by more than a
% minute
%
% JC 2012-07-31

if nargin < 2
    resetStopTime = false;
end

keys = [];

MAX_ERROR = 60000;

stimKeys = fetch(acq.Stimulation(sessKeys) - acq.StimulationIgnore);
for key = stimKeys'
    % make sure stim file exists. If Matlab crashes or is killed, we have
    % to recover it from the trial backups on the Mac
    stimulation = acq.Stimulation(key);
    stimFile = getFileName(stimulation);
    if ~exist(stimFile, 'file')
        warning(sprintf('Stimulation file not found: %s\nRecover from Mac first, then try again!', stimFile))
    end
    
    % create stop_time entries if missing
    stimStopTime = fetch1(stimulation, 'stim_stop_time');

    stim = getfield(load(stimFile), 'stim'); %#ok
    if isempty(stim.events)
            predictedStimStopTime = key.stim_start_time;
    else
            duration = (stim.params.constants.endTime - stim.params.constants.startTime) * 1000;
            predictedStimStopTime = key.stim_start_time + fix(duration);
    end
    
    if abs(predictedStimStopTime - stimStopTime) > MAX_ERROR
        keys = [keys key];
    end
    
end

if resetStopTime
    disp(['Resetting stop time of ' num2str(length(keys)) ' here']);
    for i = 1:length(keys)
        update(acq.Stimulation & keys(i), 'stim_stop_time', NaN);
    end
end