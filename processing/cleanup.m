function cleanup(sessKeys)
% Cleanup database entries (before processing a session)
%   cleanup(sessKey) 
%   
%   * Fixes missing *_stop_time database entries
%   * Updates t0 in raw data files
%
% AE 2011-10-10

sessionStopTime = 0;
schema = acq.Sessions.table.schema.dbname;

assert(count(acq.Sessions(sessKeys)) == 1, ...
    'Updated the session stop time fails for multiple keys');

aodScansKeys = fetch(acq.AodScan(sessKeys)); % - acq.EphysIgnore);
for key = aodScansKeys'
    % update t0 in raw data file
    aod = acq.AodScan(key);
    try
        updateT0(getFileName(aod), getHardwareStartTime(aod));
    catch err
        warning('Could not update t0 in file %s\nError message: %s\n', getFileName(aod), err.message) %#ok
        continue
    end
    
    % create stop_time entries if missing
    aodStopTime = fetch1(aod, 'aod_scan_stop_time');
    if isnan(aodStopTime)
        br = getFile(aod,'Temporal');
        duration = 1000 * length(br) / getSamplingRate(br);
        close(br);
        aodStopTime = key.aod_scan_start_time + fix(duration);
        mym(sprintf(['UPDATE `%s`.`aod_scan` SET `aod_scan`.`aod_scan_stop_time` = %16.16g WHERE ' ...
            '`aod_scan`.`aod_scan_start_time` = %16.16g AND `aod_scan`.`session_start_time` = %16.16g AND ' ...
            '`aod_scan`.`setup` = %u'], schema, aodStopTime, key.aod_scan_start_time, key.session_start_time, key.setup));
        fprintf('Updated aod_scan_stop_time field (aod_scan_start_time = %ld)\n', key.aod_scan_start_time)
    end
    sessionStopTime = max(sessionStopTime, aodStopTime);
end

% TODO: In the case that ephys is recorded on setup four a regression must
% be performed against something else because the sampling rate is
% imperfect
ephysKeys = fetch(acq.Ephys(sessKeys) - acq.EphysIgnore);
for key = ephysKeys'
    % update t0 in raw data file
    ephys = acq.Ephys(key);
    try
        updateT0(getFileName(ephys), getHardwareStartTime(ephys));
    catch err
        warning('Could not update t0 in file %s\nError message: %s\n', getFileName(ephys), err.message) %#ok
        continue
    end
    
    % create stop_time entries if missing
    ephysStopTime = fetch1(ephys, 'ephys_stop_time');
    if isnan(ephysStopTime)
        br = getFile(ephys);
        duration = 1000 * length(br) / getSamplingRate(br);
        close(br);
        ephysStopTime = key.ephys_start_time + fix(duration);
        mym(sprintf(['UPDATE `%s`.`ephys` SET `ephys`.`ephys_stop_time` = %16.16g WHERE ' ...
            '`ephys`.`ephys_start_time` = %16.16g AND `ephys`.`session_start_time` = %16.16g AND ' ...
            '`ephys`.`setup` = %u'], schema, ephysStopTime, key.ephys_start_time, key.session_start_time, key.setup));
        fprintf('Updated ephys_stop_time field (ephys_start_time = %ld)\n', key.ephys_start_time)
    end
    sessionStopTime = max(sessionStopTime, ephysStopTime);
end

behKeys = fetch(acq.BehaviorTraces(sessKeys) - acq.BehaviorTracesIgnore);
for key = behKeys'
    % update t0 in raw data file
    beh = acq.BehaviorTraces(key);
    try
        updateT0(getFileName(beh), getHardwareStartTime(beh));
    catch err
        warning('Could not update t0 in file %s\nError message: %s\n', getFileName(beh), err.message) %#ok
        continue
    end
    
    % create stop_time entries if missing
    behStopTime = fetch1(beh, 'beh_stop_time');
    if isnan(behStopTime)
        br = getFile(beh);
        duration = 1000 * length(br) / getSamplingRate(br);
        close(br);
        behStopTime = key.beh_start_time + fix(duration);
        mym(sprintf(['UPDATE `%s`.`behavior_traces` SET `behavior_traces`.`beh_stop_time` = %16.16g WHERE ' ...
            '`behavior_traces`.`beh_start_time` = %16.16g AND `behavior_traces`.`session_start_time` = %16.16g AND ' ...
            '`behavior_traces`.`setup` = %u AND `behavior_traces`.`stim_start_time` = %16.16g'], schema, behStopTime, ...
            key.beh_start_time, key.session_start_time, key.setup, key.stim_start_time));
        fprintf('Updated beh_stop_time field (beh_start_time = %ld)\n', key.beh_start_time)
    end
    sessionStopTime = max(sessionStopTime, behStopTime);
end

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
    if isnan(stimStopTime)
        stim = getfield(load(stimFile), 'stim'); %#ok
        if isempty(stim.events)
            stimStopTime = key.stim_start_time;
            totalTrials = 0;
            correctTrials = 0;
            incorrectTrials = 0;
        else
            duration = (stim.params.constants.endTime - stim.params.constants.startTime) * 1000;
            stimStopTime = key.stim_start_time + fix(duration);
            valid = [stim.params.trials.validTrial];
            correct = [stim.params.trials.correctResponse];
            totalTrials = numel(valid);
            correctTrials = sum(valid & correct);
            incorrectTrials = sum(valid & ~correct);
        end
        mym(sprintf(['UPDATE `%s`.`stimulation` SET `stimulation`.`stim_stop_time` = %16.16g, ' ...
            '`stimulation`.`total_trials` = %d, ' ...
            '`stimulation`.`correct_trials` = %d, `stimulation`.`incorrect_trials` = %d WHERE ' ...
            '`stimulation`.`stim_start_time` = %16.16g AND `stimulation`.`session_start_time` = %16.16g AND ' ...
            '`stimulation`.`setup` = %u'], schema, stimStopTime, totalTrials, correctTrials, ...
            incorrectTrials, key.stim_start_time, key.session_start_time, key.setup));
        fprintf('Updated stim_stop_time and *_trials fields (stim_start_time = %ld)\n', key.stim_start_time)
    end
    sessionStopTime = max(sessionStopTime, stimStopTime);
end

% create session stop time entry if missing
for sessKey = sessKeys'
    if isnan(fetch1(acq.Sessions(sessKey), 'session_stop_time'))
        tsKey = sessKey;
        tsKey.timestamper_time = fetch1(acq.Sessions, acq.SessionTimestamps(sessKey), 'MAX(timestamper_time) -> m');
        duration = acq.SessionTimestamps.getRealTimes(acq.SessionTimestamps(tsKey));
        sessionStopTime = max(sessionStopTime, sessKey.session_start_time + ceil(duration));
        mym(sprintf(['UPDATE `%s`.`sessions` SET `sessions`.`session_stop_time` = %16.16g WHERE ' ...
            '`sessions`.`session_start_time` = %16.16g AND `sessions`.`setup` = %u'], ...
            schema, sessionStopTime, sessKey.session_start_time, sessKey.setup));
        fprintf('Updated session_stop_time field (session_start_time = %ld)\n', sessKey.session_start_time)
    end
end