function recoverMissingBehaviorTraces(cond)
% This function reconstructs missing behavior traces from the file system.
%    e.g. recoverMissingBehaviorTraces('subject_id = 5')
%
% AE 2012-01-18

% find sessions that have missing behavior traces
keys = fetch(acq.Sessions(cond) - acq.SessionsIgnore & (acq.Stimulation('total_trials > 0') - acq.BehaviorTraces));

for key = keys'
    
    [sessionPath, subjectName] = fetch1(acq.Sessions(key) * acq.Subjects, 'session_path', 'subject_name');
    
    % read messages
    msgFile = fullfile(findFile(RawPathMap, sessionPath), 'messages.csv');
    msgFileId = fopen(msgFile, 'r');
    msg = textscan(msgFileId, '%d%s%s%s%s', 'Delimiter', ',');
    fclose(msgFileId);
    
    % determine time zone offset from UTC (necessary to create timestamps from
    % date strings since date strings are in Central Time whereas timestamps
    % are in UTC)
    timeOffset = getTimeOffset(acq.Sessions(key));
    msgToLabview = @(t) dateToLabviewTime(t, 'HH:MM:SS.FFF AM mm/dd/yyyy') - timeOffset;
    
    % recover behavior traces
    stimFoldersWithoutBT = fetchn((acq.Stimulation(key) & 'total_trials > 0') - acq.BehaviorTraces, 'stim_path');
    stimNdx = find(msg{1} == 1 & cellfun(@(x) strcmp(x(1:12), '/stimulation'), msg{3}));
    behNdx = find(msg{1} == 0 & cellfun(@(x) strcmp(x, 'BehaviorData'), msg{2}));
    whichBehNdx = find(ismember(msg{3}(stimNdx), stimFoldersWithoutBT));
    for i = whichBehNdx'
        beh = fetch(acq.Stimulation(['stim_path = "' msg{3}{stimNdx(i)} '"']));
        beh.beh_start_time = msgToLabview(msg{4}{behNdx(i)});
        k = strfind(msg{3}{behNdx(i)}, subjectName);
        beh.beh_path = ['/raw/' strrep(msg{3}{behNdx(i)}(k:end), '\', '/') '%d.h5'];
        beh.beh_traces_type = 'analog';
        findFile(RawPathMap, sprintf(beh.beh_path, 0)); % to make sure we're not inserting crap
        inserti(acq.BehaviorTraces, beh);
        fprintf('Recovered %s\n', beh.beh_path)
    end
end
