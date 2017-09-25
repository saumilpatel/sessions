function [stimNet, rms] = syncNetworkFewTrials(stim, key)

params.maxRoundtrip = 5;

if isempty(stim.events)
    stimNet = stim;
    rms = -1;
    return  % empty file; nothing to do
end

sy = [stim.params.trials.sync];
s = [sy.start];
e = [sy.end];
r = [sy.response];
mid = (s + e) / 2; % these are the mac times
mid = mid / 1e3;  % sync times are in ms

% to convert from mac time to pc counter use p(2) * mac + p(1)
i = (e - s) < params.maxRoundtrip;
assert(sum(i) / numel(i) > 0.8, 'Too many sync packets dropped')
p = flipud(regress(r'-mean(r),[mid'-mean(mid) ones(length(mid),1)]));
p(1) = -mean(mid)*p(2) + mean(r);
rms = sqrt(mean((p(2) * mid + p(1) - r).^2));

% get the "zero" time of the counter that was used for network
% sync relative to session time
t0 = getHardwareStartTime(acq.BehaviorTraces(key));

assert(~isempty(t0), ['Could not find the hardware time stamp for behavioral session: ' fetch1(acq.BehaviorTraces(key),'beh_path')])
stimNet = convertStimTimes(stim, p, [0; 1]);
stimNet = convertStimTimes(stimNet, [t0; 1], [t0; 1]);
stimNet.synchronized = 'network';
