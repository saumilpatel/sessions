function sDb = fixNullStopTimes(sDb)


dat = mym('SELECT * FROM stimulation WHERE ISNULL(stim_stop_time)');
stim = parseMym(sDb, dat);

for i = 1:length(stim)
    try
        stimFile = getStimFile(sDb, stim(i));
        lvSources = find(stimFile.eventSites==1);
        eventSources = [stimFile.events.types];
        eventTimes = [stimFile.events.times];
        firstTime = min(eventTimes(ismember(eventSources,lvSources)));
        lastTime = max(eventTimes(ismember(eventSources,lvSources)))
        
        disp(['Need to write insert function' stim(i).stim_path]);
    catch
        disp(['Failed to fix ' stim(i).stim_path]);
    end
end


dat = mym('SELECT * FROM ephys WHERE ISNULL(ephys_stop_time)');
ephys = parseMym(sDb, dat);

for i = 1:length(ephys)
    try
        brEphys = getEphysFile(sDb, ephys(i));        
        recLen = range(brEphys([1 end],'t'));        
	stopTime = round(ephys(i).ephys_start_time + recLen);
	disp(['Start is ' num2str(ephys(i).ephys_start_time) ' and stop is ' stopTime]);
        disp('Need to write insert function');
    catch
        disp(['Failed to fix ' ephys(i).ephys_path]);
    end
end


dat = mym('SELECT * FROM behavior_traces WHERE ISNULL(beh_stop_time)');
beh = parseMym(sDb, dat);

for i = 1:length(beh)
    try
        brBeh = getEphysFile(sDb, beh(i));        
        recLen = range(brBeh([1 end],'t'));        
	stopTime = round(beh(i).beh_start_time + recLen)
	disp(['Start is ' num2str(beh(i).beh_start_time) ' and stop is ' stopTime]);
        disp('Need to write insert function');
    catch
        disp(['Failed to fix ' beh(i).beh_path]);
    end
end

