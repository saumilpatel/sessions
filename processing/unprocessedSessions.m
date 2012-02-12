function keys = unprocessedSessions(subjectIds, fromDate, toDate)
% List unprocessed sessions
%   keys = unprocessedSessions(subjectIds, fromDate, toDate)
%
% AE 2012-02-09

if nargin < 2
    fromDate = '2000-00-00';
end
if nargin < 3
    toDate = datestr(now(), 'yyyy-mm-dd HH:MM:SS');
end
if ~ischar(subjectIds)
    subjectIds = sprintf('%d,', subjectIds);
    subjectIds = subjectIds(1:end-1);
end
condition = 'subject_id IN (%s) AND session_datetime > "%s" AND session_datetime < "%s"';
keys = fetch(acq.Sessions(sprintf(condition, subjectIds, fromDate, toDate)) ...
                - acq.SessionsIgnore - detect.Params);

disp('The following sessions have not been processed yet:')
disp(fetchn(acq.Sessions(keys), 'session_path'))
            