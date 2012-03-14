function processSession(sDb,sessKey)
% Process a sessionDb Ephys recording
%
% JC 2011-10-05

%{
Process Session

1. For each recording file in session updateT0
2. For each element in session verify the stop times are valid
3. For each ephys
  3.1. For each stimulation that overlaps
    3.1.1. Synchronize
    3.1.2. Create clus_time_set (if does not exist)
    3.1.3. Insert clus_times
  3.2. If a clus_time_set was created insert a detection_set_param with
       appropriate method
4. Create entry that will cause the processing to occur

%}

%keys = fetch(Sessions('setup=2') .* Subjects('subject_name="Woody"') .* Ephys);
%sessKey = keys(1);

import sessions.*;
import ephys.*;

ephysKeys = fetch(Ephys(sessKey));
stimKeys = fetch(Stimulation(sessKey,'correct_trials > 100'));
behKeys = fetch(BehaviorTraces(sessKey));

for stimKey = stimKeys'
    % TODO: Check stop time
end

for behKey = behKeys'
    beh = fetch(BehaviorTraces(behKey), '*');
    t0 = getHardwareStartTime(sDb, behKey);
    updateT0(getLocalPath(rawToSource(sDb, beh.beh_path)), t0);
    
    if isnan(beh.beh_stop_time)
        br = getBehFile(sDb,beh);
        duration = diff(br([1 end], 't'));
        close(br);
        beh.beh_stop_time = beh.beh_start_time + round(duration);
        mym(sprintf(['UPDATE `acq`.`behavior_traces` SET `behavior_traces`.`beh_stop_time` = %16.16g WHERE ' ...
            '`behavior_traces`.`beh_start_time` = %16.16g AND `behavior_traces`.`session_start_time` = %16.16g AND ' ...
            '`behavior_traces`.`setup` = %u AND `behavior_traces`.`stim_start_time` = %16.16g'], beh.beh_stop_time, ...
            beh.beh_start_time, beh.session_start_time, beh.setup, beh.stim_start_time));
    end
end

for ephysKey = ephysKeys'
    ephys = fetch(Ephys(ephysKey),'*');
        
    % TODO: Update T0
    t0 = getHardwareStartTime(sDb, ephysKey);
    updateT0(getLocalPath(rawToSource(sDb, fetch1(sessions.Ephys(ephysKey),'ephys_path'))), t0);

    % TODO: Check stop time
    if isnan(ephys.ephys_stop_time)
        br = getEphysFile(sDb, ephys, 'Photodiode');
        duration = diff(br([1 end], 't'));
        close(br);
        ephys.ephys_stop_time = ephys.ephys_start_time + round(duration);
        mym(sprintf(['UPDATE `acq`.`ephys` SET `ephys`.`ephys_stop_time` = %16.16g WHERE ' ...
            '`ephys`.`ephys_start_time` = %16.16g AND `ephys`.`session_start_time` = %16.16g AND ' ...
            '`ephys`.`setup` = %u'], ephys.ephys_stop_time, ephys.ephys_start_time, ephys.session_start_time, ...
            ephys.setup));
        ephys = fetch(Ephys(ephysKey),'*');
    end

    foundStim = false; 

    % Create ephys times set but don't insert it unless a stimulation is found
    detectionSetParam = ephysKey;
                
    outPath = ephys.ephys_path;
    outPath(1:4) = []; % Strip out M:
    outPath = strrep(outPath, '\','/');
    outPath = ['/processed' outPath];
    detectionSetParam.ephys_processed_path = fileparts(outPath);

    for stimKey = stimKeys'
        stim = fetch(Stimulation(stimKey),'*');
        
        if isnan(stim.stim_stop_time)
            [fn stimFile] = getStimFile(sessions.Stimulation(stimKey));
            duration = (stimFile.params.constants.endTime - stimFile.params.constants.startTime) * 1000;
            stim.stim_stop_time = stim.stim_start_time + duration;
            stim.correct_trials = sum([stimFile.params.trials.correctResponse] & [stimFile.params.trials.validTrial]);
            stim.incorrect_trials = sum([stimFile.params.trials.correctResponse] == 0 & [stimFile.params.trials.validTrial]);
            stim.total_trials = length([stimFile.params.trials.validTrial]);
            
            mym(sprintf(['UPDATE `acq`.`stimulation` SET `stimulation`.`stim_stop_time` = %16.16g, ' ...
                '`stimulation`.`total_trials` = %d , `stimulation`.`correct_trials` = %d , `stimulation`.`incorrect_trials` = %d' ...
                ' WHERE ' ...
                '`stimulation`.`stim_start_time` = %16.16g AND `stimulation`.`session_start_time` = %16.16g AND ' ...
                '`stimulation`.`setup` = %u'], stim.stim_stop_time, stim.total_trials, stim.correct_trials, stim.incorrect_trials, ...
                stim.stim_start_time, stim.session_start_time, stim.setup));
            
            stim = fetch(Stimulation(stimKey),'*');
        end
        
        
        if(stim.stim_start_time > ephys.ephys_start_time & stim.stim_stop_time < (ephys.ephys_stop_time + 1000))
%            if labviewTimeToDate(sDb, stim.stim_start_time) <= datenum('July 17 2011')
%                success = synchronizeOldStim(sDb,ephys,stim);
%            else
                success = synchronizeStim(sDb,ephys,stimKey);
%            end
            
            
            if success
                % Because we found a linked stimulation insert this set
                if ~foundStim
                    detectionSetParam.detect_method_num = fetch1(detect.Methods('detect_method_name="Utah"'),'detect_method_num');
                    insert(detect.Params, detectionSetParam);
                    foundStim = true;
                end
                
                populate(acq.EphysStimulationLink,stimKey);
            end
        end
    end    
end

