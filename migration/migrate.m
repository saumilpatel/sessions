function migrate(con)
% Migrate data from +sessions to +acq
%   migrate(con) where con is a handle to an open mym connection.
%
% AE 2011-10-09

copyTable(con, acq.TimestampSources);
copyTable(con, acq.Subjects);

selFields = {'subject_id', 'setup', 'session_start_time', 'session_stop_time', 'experimenter', 'REPLACE(CONCAT("/raw", SUBSTRING(session_path, 3)), "\\", "/") as session_path', 'session_datetime'};
insFields = {'subject_id', 'setup', 'session_start_time', 'session_stop_time', 'experimenter', 'session_path', 'session_datetime'};
copyTable(con, acq.Sessions, selFields, insFields);

copyTable(con, acq.SessionTimestamps)

ephys_path = 'REPLACE(CONCAT("/raw", SUBSTRING(IF(SUBSTRING(ephys_path, -3) = ".h5", ephys_path, CONCAT(ephys_path, "%d.h5")), 3)), "\\", "/") as ephys_path';
selFields = {'subject_id', 'setup', 'session_start_time', 'ephys_start_time', 'ephys_stop_time', ephys_path, 'ephys_task'};
insFields = {'subject_id', 'setup', 'session_start_time', 'ephys_start_time', 'ephys_stop_time', 'ephys_path', 'ephys_task'};
copyTable(con, acq.Ephys, selFields, insFields);

selFields = {'subject_id', 'setup', 'session_start_time', 'stim_start_time', 'stim_stop_time', 'stim_path', 'exp_type', 'total_trials', '(correct_trials+incorrect_trials) as valid_trials', 'correct_trials', 'incorrect_trials'};
insFields = {'subject_id', 'setup', 'session_start_time', 'stim_start_time', 'stim_stop_time', 'stim_path', 'exp_type', 'total_trials', 'valid_trials', 'correct_trials', 'incorrect_trials'};
copyTable(con, acq.Stimulation, selFields, insFields);

beh_path = 'REPLACE(CONCAT("/raw", SUBSTRING(IF(SUBSTRING(beh_path, -3) = ".h5", beh_path, CONCAT(beh_path, "%d.h5")), 3)), "\\", "/") as beh_path';
selFields = {'subject_id', 'setup', 'session_start_time', 'stim_start_time', 'beh_start_time', 'beh_stop_time', beh_path, 'beh_traces_type'};
insFields = {'subject_id', 'setup', 'session_start_time', 'stim_start_time', 'beh_start_time', 'beh_stop_time', 'beh_path', 'beh_traces_type'};
copyTable(con, acq.BehaviorTraces, selFields, insFields);

copyTable(con, acq.TberPulses)

if ~count(detect.Methods)
    tuple = struct('detect_method_num', {1 2 3}, 'detect_method_name', {'Utah', 'Tetrodes', 'SiliconProbes'});
    insert(detect.Methods, tuple);
end

if ~count(sort.Methods)
    tuple = struct('sort_method_num', {1 2}, 'sort_method_name', {'Utah', 'TetrodesMoG'});
    insert(sort.Methods, tuple);
end

% fix wrong session_start_times
fixSessionStartTimes()

% Fix wrong stim_start_times due to session manager bug
sessKeys = fetch(acq.Sessions('subject_id > 0'));
fixStimStartTimes(sessKeys)



function copyTable(con, rel, selFields, insFields)

schema = acq.Ephys.table.schema.dbname;
name = ['`' rel.table.info.name '`'];
fprintf('Copying table %s\n', name)

fields = rel.table.fields;

keys = {fields([fields.iskey]).name};
keys = sprintf('%s,', keys{:}); keys = keys(1:end-1);

if nargin < 3, selFields = {fields.name}; end
if nargin < 4, insFields = {fields.name}; end

selFields = sprintf('%s,', selFields{:}); selFields = selFields(1:end-1);
insFields = sprintf('%s,', insFields{:}); insFields = insFields(1:end-1);

% add subject_id to primary key of descendants of sessions table
if ~strcmp(rel.table.info.name, 'sessions') && ~isempty(strfind(keys, 'setup')) && ~isempty(strfind(keys, 'session_start_time')) 
    selName = [name ' NATURAL JOIN sessions.sessions'];
else
    selName = name;
end

str = 'INSERT INTO %s.%s (%s) SELECT %s FROM sessions.%s WHERE (%s) NOT IN (SELECT %s FROM %s.%s)';
query = sprintf(str, schema, name, insFields, selFields, selName, keys, keys, schema, selName);
mym(con, query);
