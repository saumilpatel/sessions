function db = sessionDB(db)
% Sessions database.
%   db = sessionDB();
%
% JC 2011-05-31

if nargin == 1 && isa(db,'sessionDB')
    return
end

% Locate connection information and load it
% db.user = 'timestamper';
% db.pass = '0815';
% db.db = 'sessions';
% db.hostname = 'at-storage.neusc.bcm.tmc.edu';
% db.channelMap = {'BehaviorTraces','Stimulation','Electrophysiology'};
% db.conHandle = mym('open', db.hostname, db.user, db.pass);
% mym(db.conHandle, ['use ' db.db]);

db.source = {'E:', 'K:', 'L:', 'M:'};
db.scratch = 'F:';
db.destination = 'C:';
db = class(db,'sessionDB');
