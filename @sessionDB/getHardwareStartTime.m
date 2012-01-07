function time = getHardwareStartTime(sDb, primaryKey)
% Get the hardware start time associated with a session db entry
%
% time = getHardwareStartTime(sDb, primaryKey)
%
% JC 2011-10-05

assert(length(primaryKey) == 1, 'Can only perform on one entry');

if(isfield(primaryKey,'beh_start_time'))
    % This is a behavioral trace
    ts = sessions.SessionTimestamps(sprintf('ABS(timestamper_time -%16.16g) < 5500', ...
        primaryKey.beh_start_time)) .* sessions.TimestampSources('source="Behavior"') .* (sessions.Sessions * sessions.BehaviorTraces(primaryKey));
elseif(isfield(primaryKey,'ephys_start_time'))
    ts = sessions.SessionTimestamps(sprintf('ABS(timestamper_time -%16.16g) < 5500', ...
        primaryKey.ephys_start_time)) .* sessions.TimestampSources('source="Ephys"') .* (sessions.Sessions * sessions.Ephys(primaryKey));
else
    % This is a behavioral trace
    error('Key does not have a hardware start time');
end

ts = fetch(ts,'*');

time = counterToTime(sDb, ts);

assert(length(time) == length(primaryKey), 'Not all keys got a match')
