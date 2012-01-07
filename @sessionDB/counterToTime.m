function accurateTime = counterToTime(sDb, ts)
% Convert hardware counter times to real times accounting for wraparound
%
% accurateTime = counterToTime(sDb, ts);
% 
% JC 2011-10-05

%% Rescale to times
counterRate = 10e6 / 1000; % pulses / ms (should be stored somewhere)
counterPeriod = (2^32) / counterRate;

countTime = [ts.count] / counterRate;
approximateSessionTime = [ts.timestamper_time] - [ts.session_start_time];

% Compute expected counter value based on CPU time
approximateSessionPeriods = floor(approximateSessionTime / counterPeriod);
approximateResidualPeriod = mod(approximateSessionTime, counterPeriod);

% Correct edge cases where number of periods is off by one
idx = find((approximateResidualPeriod-countTime) > counterPeriod / 2);
approximateSessionPeriods(idx) = approximateSessionPeriods(idx) + 1;

idx = find((approximateResidualPeriod-countTime) < -counterPeriod / 2);
approximateSessionPeriods(idx) = approximateSessionPeriods(idx) - 1;

accurateTime = countTime + approximateSessionPeriods * counterPeriod;
