function stim = convertStimTimes(stim, macPar, behPar)
% Converts times in stimulation structure to global reference clock.
%   stim = convertStimTimes(stim, macPar, behPar) converts the times to the
%   global reference clock using a linear mapping. Times are converted
%   using 
%       t_global = macPar(1) + macPar(2) * t_mac
%       t_global = behPar(1) + behPar(2) * t_beh
%   where t_mac are timestamps acquired by the Mac and t_beh are timestamps
%   acquired by the state system.
%
% AE 2011-04-14

for i = 1:length(stim.events)
    % events
    ndx = logical(stim.eventSites(stim.events(i).types));
    stim.events(i).times(~ndx) = macPar(1) + macPar(2) * stim.events(i).times(~ndx);
    stim.events(i).times(ndx) = behPar(1) + behPar(2) * stim.events(i).times(ndx);

    % buffer swaps
    stim.params.trials(i).swapTimes = macPar(1) + macPar(2) * stim.params.trials(i).swapTimes;
end

% start & end time
stim.params.constants.startTime = macPar(1) + macPar(2) * stim.params.constants.startTime;
stim.params.constants.endTime = macPar(1) + macPar(2) * stim.params.constants.endTime;
