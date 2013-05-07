function processChronicTetrodeSession(key, mua)
% Process chronic tetrode session.
%
% AE 2013-05-06

if nargin < 2
    mua = false;
end

processSession(key)

% extract multi unit as well?
if mua
    keys = fetch(sort.Params & key);
    createSortSet(keys, 'MultiUnit');
end

populate(detect.Sets, key)
populate(sort.Sets, key)

keys = fetch(sort.Electrodes & key);
parfor i = 1 : numel(keys)
    populate(sort.KalmanAutomatic, keys(i))
end

if mua
    populate(sort.MultiUnit, key)
    populate(sort.SetsCompleted, key)
    populate(ephys.SpikeSet, key)
    populate(stimulation.StimTrialGroup, key)
    populate(v1.ReceptiveFields, key)
end
