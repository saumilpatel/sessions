function [fixedKeys, errKeys] = fixSessionStartTimes()


fixedKeys = [];
errKeys = [];

% first fix stimulations
stimKeys = fetch(acq.Stimulation);
for stimKey = stimKeys'
    stim = acq.Stimulation(stimKey);
    stimStartTime = fetch1(stim, 'stim_start_time');
    sessionKeys = rmfield(rmfield(stimKey, 'session_start_time'), 'subject_id');
    sessionKeys = fetch(acq.Sessions(sessionKeys));
    sessionStartTimes = fetchn(acq.Sessions(sessionKeys), 'session_start_time');
    [sessionStartTimes, order] = sort(sessionStartTimes);
    sessionStartTimes(end+1) = Inf; %#ok
    sessionKeys = sessionKeys(order);
    correctSession = find(sessionStartTimes(1:end-1) < stimStartTime & sessionStartTimes(2:end) > stimStartTime, 1, 'first');
    if sessionKeys(correctSession).session_start_time ~= stimKey.session_start_time
        % found mismatch
        s = fetch(stim, '*');
        s.subject_id = sessionKeys(correctSession).subject_id;
        s.session_start_time = sessionKeys(correctSession).session_start_time;
                
        b = fetch(acq.BehaviorTraces(stimKey), '*');
        if ~isempty(b)
            [b.subject_id] = deal(s.subject_id);
            [b.session_start_time] = deal(s.session_start_time);
            [b.stim_start_time] = deal(s.stim_start_time);
        end
        
        p = fetch(acq.TberPulses(stimKey), '*');
        if ~isempty(p)
            [p.subject_id] = deal(s.subject_id);
            [p.session_start_time] = deal(s.session_start_time);
            [p.stim_start_time] = deal(s.stim_start_time);
        end
        
        del(stim, false);
        
        % try inserting. in case it's been re-inserted by migration script,
        % insert will fail because it already exists
        try insert(acq.Stimulation, s); end %#ok  
        try insert(acq.BehaviorTraces, b); end %#ok
        try insert(acq.TberPulses, p); end %#ok
    end
end


% Now fix behavior traces
threshold = 6000;   % if offset by more than this we consider times non-matching
behKeys = fetch(acq.BehaviorTraces);
for behKey = behKeys'
    beh = acq.BehaviorTraces(behKey);
    sessionPath = fetch1(acq.Sessions * beh, 'session_path');
    sessionPath = regexp(sessionPath, '(\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2})', 'tokens', 'once');
    behPath = fetch1(beh, 'beh_path');
    sessionPathBeh = regexp(behPath, '(\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2})', 'tokens', 'once');
    if ~isequal(sessionPathBeh{1}, sessionPath{1})
        % found mismatch
        b = fetch(acq.BehaviorTraces(behKey), '*');
        correctSession = acq.Sessions & sprintf('session_path LIKE "%%%s"', sessionPathBeh{1});
        if count(correctSession) == 1
            
            d = fetch1(correctSession, 'session_datetime');
            sessKey = fetch(correctSession);
            sst = fetchn(acq.Stimulation(sessKey), 'stim_start_time');
            bbt = fetch1(beh, 'beh_start_time');
            
            % now try finding matches with stim_start_times in stimulation table
            [m, ndx] = min(abs(sst - bbt), [], 1);
            if m < threshold
                [b.subject_id, b.setup, b.session_start_time] = ...
                    fetch1(correctSession, 'subject_id', 'setup', 'session_start_time');
                b.stim_start_time = sst(ndx);
                del(acq.BehaviorTraces(behKey), false);
                try insert(acq.BehaviorTraces, b); end %#ok
                fixedKeys = [fixedKeys, behKey]; %#ok
                fprintf('Fixed %s\n', fetch1(acq.Sessions(behKey), 'session_datetime'));
            else
                fprintf('Did not find matching stims for all behTraces (max error = %.2f sec) in session %s\n', max(m) / 1000, d)
                errKeys = [errKeys sessKey]; %#ok
            end
        else
            errKeys = [errKeys, behKey]; %#ok
            fprintf('Could not fix BehaviorTrace %s\n', b.beh_path);
        end
    end
end
