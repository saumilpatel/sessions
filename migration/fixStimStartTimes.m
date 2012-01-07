function [fixedKeys, errKeys] = fixStimStartTimes(sessKeys)
% Fix non-matching stim_start_times in BehaviorTraces table.
%   [fixedKeys, errKeys] = fixStimStartTimes(sessKeys) corrects
%   non-matching stim_start_times in the BehaviorTraces tables. This fixes
%   a bug in an early version of the session manager.
%
% AE 2011-10-16

threshold = 6000;   % if offset by more than this we consider times non-matching
errKeys = [];
fixedKeys = [];
for sessKey = sessKeys'
    d = fetch1(acq.Sessions(sessKey), 'session_datetime');
    sst = fetchn(acq.Stimulation(sessKey), 'stim_start_time');
    [bst, bbt] = fetchn(acq.BehaviorTraces(sessKey), 'stim_start_time', 'beh_start_time');
    
    % first check if stim_start_times in behavior table make sense
    if all(bbt - bst > -10 & bbt - bst < threshold)
        fprintf('Everything alright with session %s\n', d)
        continue
    end
    
    % now try finding matches with stim_start_times in stimulation table
    [m, ndx] = min(abs(bsxfun(@minus, sst, bbt')), [], 1);
    if all(m < threshold) || true % DOESN'T SEEM NECESSARY 
        replaceRow(sessKey, sst(ndx));
        fixedKeys = [fixedKeys sessKey]; %#ok
    else
        fprintf('Did not find matching stims for all behTraces (max error = %.2f sec) in session %s\n', max(m) / 1000, d)
        errKeys = [errKeys sessKey]; %#ok
    end
end


function replaceRow(sessKey, t)

b = fetch(acq.BehaviorTraces(sessKey), '*');
t = num2cell(t);
[b.stim_start_time] = deal(t{:});
del(acq.BehaviorTraces(sessKey), false);
try insert(acq.BehaviorTraces, b); end %#ok   if re-inserted by migration script this will fail (which is ok)
fprintf('Fixed session %s\n', fetch1(acq.Sessions(sessKey), 'session_datetime'));
