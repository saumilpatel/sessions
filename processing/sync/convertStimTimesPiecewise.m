function stim = convertStimTimesPiecewise(stim, macPar, segments)
% Converts times in stimulation structure to global reference clock.
%   stim = convertStimTimes(stim, macPar, segments) converts the times to
%   the global reference clock using a linear mapping. Times are converted
%   using
%       t_global = macPar(1) + macPar(2) * t_mac
%   where t_mac are timestamps acquired by the Mac
%
% AE 2012-01-19

% extrapolate if necessary
segments(1) = -Inf;
segments(end) = Inf;

% events
trial = 1;
seg = 1;
while trial < numel(stim.events) && seg < numel(segments)
    macEvents = find(~stim.eventSites(stim.events(trial).types));
    macEventTimes = stim.events(trial).times(macEvents);
    inSegment = macEventTimes > segments(seg) & macEventTimes <= segments(seg+1);
    stim.events(trial).times(macEvents(inSegment)) = macPar(1,seg) + macPar(2,seg) * macEventTimes(inSegment);
    if inSegment(end)
        trial = trial + 1;
    else
        seg = seg + 1;
    end
end

% buffer swaps
trial = 1;
seg = 1;
while trial < numel(stim.events) && seg < numel(segments)
    macSwapTimes = stim.params.trials(trial).swapTimes;
    inSegment = macSwapTimes > segments(seg) & macSwapTimes <= segments(seg+1);
    stim.params.trials(trial).swapTimes(inSegment) = macPar(1,seg) + macPar(2,seg) * macSwapTimes(inSegment);
    if inSegment(end)
        trial = trial + 1;
    else
        seg = seg + 1;
    end
end

% start & end time
tstart = stim.params.constants.startTime;
seg = tstart > segments(1:end-1) & tstart <= segments(2:end);
stim.params.constants.startTime = macPar(1,seg) + macPar(2,seg) * tstart;
tend = stim.params.constants.endTime;
seg = tend > segments(1:end-1) & tend <= segments(2:end);
stim.params.constants.endTime = macPar(1,seg) + macPar(2,seg) * tend;
