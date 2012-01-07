function recoverFromFileSystem(folder)
% Recover acq table entries for acquisition session in given folder.
%   recoverFromFileSystem(folder) where folder is the base folder for the
%   session (e.g. M:\Claude\2011-10-25_11-32-15)
%
%   Note that *_start_time and *_stop_time will not be equal to the
%   original database entries but instead computed from the (approximately
%   equal) Windows timestamps (e.g. session_datetime).
%
% AE 2011-12-01

tsFile = fullfile(folder, 'timestamps.csv');
msgFile = fullfile(folder, 'messages.csv');

% make sure it's a valid folder
assert(exist(tsFile, 'file') > 0, 'Not a valid acquisition folder: %s', folder)

% mapping from subject ids to setup and experimenter
setups = [2 2 2 3 3 2 3 3];
experimenters = {'Allison', 'Allison', 'Allison', 'Mani', 'Tori', 'Mani', 'Tori', 'Tori'};
ephysTasks = {'UtahArray', 'UtahArray', 'UtahArray', 'Charles Chronic Left Tetrodes', 'Claude Chronic Left Tetrodes', 'UtahArray', 'SiliconProbes', 'SiliconProbes'};

% read timestamps
tsFileId = fopen(tsFile, 'r');
tsData = textscan(tsFileId, '%d%u64%26s', 'Delimiter', ',');
fclose(tsFileId);

% read messages
msgFileId = fopen(msgFile, 'r');
msg = textscan(msgFileId, '%d%s%s%s%s', 'Delimiter', ',');
fclose(msgFileId);

% determine time zone offset from UTC (necessary to create timestamps from
% date strings since date strings are in Central Time whereas timestamps
% are in UTC)
splitNdx = strfind(tsFile, filesep);
sessionDatetime = tsFile(splitNdx(end-1)+1:splitNdx(end)-1);
dstDates = [datenum('13 March 2011') datenum('6 November 2011') ...
            datenum('11 March 2012') datenum('4 November 2012') ...
            datenum('10 March 2013') datenum('3 November 2013') ...
            datenum('9 March 2014') datenum('2 November 2014') ...
            datenum('8 March 2015') datenum('1 November 2015')];
t = datenum(sessionDatetime, 'yyyy-mm-dd_HH-MM-SS');
dst = find(t > dstDates(1:end-1) & t < dstDates(2:end));
timeOffset = (6 - mod(dst, 2)) * 60 * 60 * 1000;  % in ms
msgToLabview = @(t) dateToLabviewTime(t, 'HH:MM:SS.FFF AM mm/dd/yyyy') + timeOffset;
toLabview = @(t) dateToLabviewTime(t, 'yyyy-mm-dd_HH-MM-SS') + timeOffset;

% recover Sessions table
timestamperTime = cellfun(msgToLabview, tsData{3}, 'UniformOutput', false);
% sessionStartTime = timestamperTime{1} - 1;
sessionStartTime = toLabview(sessionDatetime);
subjectName = tsFile(splitNdx(end-2)+1:splitNdx(end-1)-1);
subjectId = fetch1(acq.Subjects(struct('subject_name', subjectName)), 'subject_id');
setup = setups(subjectId);

sessKey.subject_id = subjectId;
sessKey.setup = setup;
sessKey.session_start_time = sessionStartTime;

sessions = sessKey;
sessions.experimenter = experimenters{subjectId};
sessions.session_path = ['/raw/' subjectName '/' sessionDatetime];
sessions.session_datetime = sessionDatetime;
sessions.hammer = 'false';
inserti(acq.Sessions, sessions)

% recover timestamps table
sessionTimestamps = struct('subject_id', subjectId, 'setup', setup, ...
    'session_start_time', sessionStartTime, 'channel', num2cell(tsData{1}), ...
    'timestamper_time', timestamperTime, 'count', num2cell(tsData{2}));
inserti(acq.SessionTimestamps, sessionTimestamps);

% recover ephys table
ephysNdx = find(msg{1} == 2);
for i = 1:numel(ephysNdx)
    if strcmp(msg{2}{ephysNdx(i)}, 'Electrophysiology')
        ephys = sessKey;
        ephys.ephys_start_time = msgToLabview(msg{4}{ephysNdx(i)});
        k = strfind(msg{3}{ephysNdx(i)}, subjectName);
        ephys.ephys_path = ['/raw/' strrep(msg{3}{ephysNdx(i)}(k:end), '\', '/')];
        ephys.ephys_task = ephysTasks{subjectId};
        inserti(acq.Ephys, ephys);
    end
end

% recover stimulation table
stimNdx = find(msg{1} == 1 & cellfun(@(x) strcmp(x(1:12), '/stimulation'), msg{3}));
stimNdx(end+1) = numel(msg{1});
for i = 1:numel(stimNdx)-1
    stimulation = sessKey;
    stimulation.stim_start_time = msgToLabview(msg{4}{stimNdx(i)});
    stimulation.stim_path = msg{3}{stimNdx(i)};
    stimulation.exp_type = msg{2}{stimNdx(i)};
    inserti(acq.Stimulation, stimulation)

    % recover behavior traces table
    beh = sessKey;
    beh.beh_start_time = msgToLabview(msg{4}{stimNdx(i)+1});
    beh.stim_start_time = stimulation.stim_start_time;
    k = strfind(msg{3}{stimNdx(i)+1}, subjectName);
    beh.beh_path = ['/raw/' strrep(msg{3}{stimNdx(i)+1}(k:end), '\', '/')];
    beh.beh_traces_type = 'analog';
    inserti(acq.BehaviorTraces, beh);
    
    % recover tber pulses
    segment = stimNdx(i)+2:stimNdx(i+1);
    pulseNdx = msg{1}(segment) == 1 & cellfun(@(x) strcmp(x, stimulation.exp_type), msg{2}(segment));
    pulseTimes = cellfun(@(s) sscanf(s, '%lu'), msg{4}(segment(pulseNdx)), 'UniformOutput', false);
    tberPulses = struct('subject_id', subjectId, 'setup', setup, ...
        'session_start_time', sessionStartTime, ...
        'stim_start_time', stimulation.stim_start_time, ...
        'tber_pulse_time', pulseTimes);
    inserti(acq.TberPulses, tberPulses)
end

1;
