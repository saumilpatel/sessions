%{
# table to record results notification to slack
-> stimulation.PerSectorStats
-----
msg = ''                    : varchar(1024) # message for the notification
sent_ts = CURRENT_TIMESTAMP : timestamp

%}

classdef NotificationSent < dj.Manual
end