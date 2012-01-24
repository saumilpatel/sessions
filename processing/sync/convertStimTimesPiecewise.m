function stim = convertStimTimesPiecewise(stim, par, offset, segments)
% Converts times in stimulation structure to global reference clock.
%   stim = convertStimTimes(stim, par, offset, segments) converts the times
%   to the ephys clock using a linear mapping. Times are
%   converted using
%       t_ephys = par(1) + par(2) * t_mac
%       t_ephys = par(1) - offset + par(2) * t_beh
%   where t_mac are timestamps acquired by the Mac and t_beh timestamps
%   acquired by Behavior. offset is the time offset between behavior and
%   Mac times after network synchronization (if the hardware clocks were
%   phase-locked this would be the only thing that we would have to
%   corrrect using the photodiode).
%
% AE 2012-01-23

% extrapolate if necessary
segments(1) = -Inf;
segments(end) = Inf;

% events
for trial = 1:numel(stim.events)
    macEvents = ~stim.eventSites(stim.events(trial).types);
    stim.events(trial).times(macEvents) = convertTimes(stim.events(trial).times(macEvents), par, 0, segments);
    stim.events(trial).times(~macEvents) = convertTimes(stim.events(trial).times(~macEvents), par, offset, segments);
end

% buffer swaps
for trial = 1:numel(stim.events)
    stim.params.trials(trial).swapTimes = convertTimes(stim.params.trials(trial).swapTimes, par, 0, segments);
end

% start & end time
stim.params.constants.startTime = convertTimes(stim.params.constants.startTime, par, 0, segments);
stim.params.constants.endTime = convertTimes(stim.params.constants.endTime, par, 0, segments);



function t = convertTimes(t, par, offset, segments)

for i = 1:numel(t)
    seg = find(t(i) > segments, 1);
    t(i) = par(1,seg) - offset + par(2,seg) * t(i);
end
