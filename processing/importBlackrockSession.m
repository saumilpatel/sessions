function importBlackrockSession(baseFolder, sessionFolder, subject, setup, experimenter, clockOffset)
% Import session recorded by Blackrock system into database
%   importBlackrockSession(baseFolder, sessionFolder, subject, setup, experimenter, clockOffset)
%   
%   It's currently assumed that all stimulation files are in
%   /stimulation/subject/<DATE>
%
%   clockOffset indicates the time offset (in ms) between the recording
%   computer's clock and the stimulation computer. This needs to be
%   estimated manually. The easiest was is to import first with
%   clockOffset=0, estimate it based on the offset between
%   ephys_start_times and stim_start_times (the latter should alsways be
%   slightly after the former), and then re-import with the correct value.
%   
% AE 2012-01-24

format = 'yyyy-mm-dd_HH-MM-SS';
ephysTask = 'Blackrock24TT';

% determine ephys start times
sessionFolder = strrep(sessionFolder, '\', '/');
if sessionFolder(end) == '/', sessionFolder(end) = []; end
ndx = find(sessionFolder == '/');
sessionStartTime = datenum(sessionFolder(ndx(end)+1:end), format);

% Subjects table
rel = acq.Subjects(sprintf('subject_name = "%s"', subject));
if count(rel)
    key.subject_id = fetch1(rel, 'subject_id');
else
    key.subject_id = max(fetchn(acq.Subjects, 'subject_id')) + 1;
    tuple = key;
    tuple.subject_name = subject;
    insert(acq.Subjects, tuple);
end

% Ephys types table
tuple = key;
tuple.setup = setup;
tuple.ephys_task = ephysTask;
tuple.ephys_type = 'Tetrodes';
tuple.default_detect_method = fetch1(detect.Methods('detect_method_name = "Tetrodes"'), 'detect_method_num');
tuple.default_sort_method = fetch1(sort.Methods('sort_method_name = "TetrodesMoG"'), 'sort_method_num');
inserti(acq.EphysTypes, tuple);

% Sessions
key.setup = setup;
key.session_start_time = dateToLabviewTime(datestr(sessionStartTime));

session = key;
session.session_stop_time = -Inf;
session.experimenter = experimenter;
session.session_path = ['/raw/' sessionFolder];
session.session_datetime = datestr(sessionStartTime, 'yyyy-mm-dd HH:MM:SS');
session.recording_software = 'Blackrock';

% Ephys recordings
d = dir(fullfile(baseFolder, sessionFolder, '*-*-*_*-*-*'));
ephys = repmat(key, numel(d), 1);
for i = 1:numel(d)
    file = dir(fullfile(baseFolder, sessionFolder, d(i).name, '*.ns5'));
    fileName = strrep(file.name, 'ns5', '*');
    br = baseReader([baseFolder '/' sessionFolder '/' d(i).name '/' fileName]);
    ephys(i).ephys_start_time = dateToLabviewTime(d(i).name, format);
    ephys(i).ephys_stop_time = ephys(i).ephys_start_time + 1000 * (getNbSamples(br) / getSamplingRate(br) + 30);
    ephys(i).ephys_path = ['/raw/' sessionFolder '/' d(i).name '/' fileName];
    ephys(i).ephys_task = ephysTask;
    close(br);
    session.session_stop_time = max(session.session_stop_time, ephys(i).ephys_stop_time);
end

% Stimulation
stimFolder = getLocalPath(['/stimulation/' subject]);
d = dir([stimFolder '/*-*-*_*-*-*']);
stimulation = repmat(key, numel(d), 1);
for i = 1:numel(d)
    files = dir(fullfile(stimFolder, d(i).name));
    [~, ndx] = max(arrayfun(@(x) length(x.name), files));
    [~, expType] = fileparts(strrep(files(ndx).name, 'Synched', ''));
    load(fullfile(stimFolder, d(i).name, expType))
    if isempty(stim.params.trials)
        stim = recover(StimulationData(stim), fullfile(stimFolder, d(i).name));
    end
    
    stimulation(i).stim_start_time = dateToLabviewTime(d(i).name, format) + clockOffset;
    stimulation(i).stim_stop_time = stimulation(i).stim_start_time + uint64(ceil(1000 * (stim.params.constants.endTime - stim.params.constants.startTime)));
    stimulation(i).stim_path = ['/stimulation/' subject '/' d(i).name];
    stimulation(i).exp_type = expType;
    stimulation(i).total_trials = numel(stim.events);
    stimulation(i).correct_trials = sum([stim.params.trials.validTrial] & [stim.params.trials.correctResponse]);
    stimulation(i).incorrect_trials = sum([stim.params.trials.validTrial] & ~[stim.params.trials.correctResponse]);
    
    session.session_stop_time = max(session.session_stop_time, stimulation(i).stim_stop_time);
end

insert(acq.Sessions, session);
insert(acq.Ephys, ephys);
insert(acq.Stimulation, stimulation);
