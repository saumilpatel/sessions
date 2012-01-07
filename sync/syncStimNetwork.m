function stimulation = syncStimNetwork(stimulation, varargin)
% Convert Mac times to behavior times using network synchronization.
%   stim = syncStimNetwork(stim)
%
% Last update: AE 2011-04-14
% Initial: JC 2008-04-15

params.maxErr = 5;
params.systemTime = [];
params.counterTime = [];
params = parseVarArgs(params, varargin{:});

% check for prior synchronization
assert(~isfield(stimulation,'synchronized') || stimulation.synchronized == 0, ...
    'syncMacToBehavior:alreadySynchronized', 'Timestamps already synchronized');

% find events to be synchronized
macEvents = find(stimulation.eventSites == 0);

% Straightforward sync now
% load up the sync times
sy = [stimulation.params.trials.sync];
s = [sy.start];
e = [sy.end];
r = [sy.response];
mid = (s + e) / 2 / 1000;

% map from the cpu time which drifts to the counter time
if (~isempty(params.systemTime) && numel(params.systemTime) == numel(params.counterTime))
    r = interp1(params.systemTime, params.counterTime, r);
end

% to convert from mac time to pc counter use p(2)*mac + p(1)
i = find((e-s) < 3);
p = robustfit(mid(i),r(i));

% detected quality of network alignment
err = r - mid * p(2) - p(1);
assert(max(abs(err)) < params.maxErr, 'syncMacToBehavior:largeResidualError', 'Minimum error exceeded');

for i = 1:length(stimulation.events)
    j = find(ismember(stimulation.events(i).types, macEvents));
    macTimes = stimulation.events(i).times(j);
    behaviorTimes = macTimes * p(2) + p(1);
    stimulation.events(i).times(j) = behaviorTimes;
end

for i = 1:length(stimulation.params.trials)
    macTimes = stimulation.params.trials(i).swapTimes;
    behaviorTimes = macTimes * p(2) + p(1);
    stimulation.params.trials(i).swapTimes = behaviorTimes;
end

stimulation.params.constants.startTime = stimulation.params.constants.startTime * p(2) + p(1);
stimulation.params.constants.endTime = stimulation.params.constants.endTime * p(2) + p(1);

% indicate what it is synced to
stimulation.synchronized = 'network';
