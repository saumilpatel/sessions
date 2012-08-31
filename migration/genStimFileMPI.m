function stim = genStimFileMPI(qnxFile, cheetahDir, expType, chtEvtBeg, chtEvtEnd, outFile)
% Generate stimulation file for old MPI data
%   The structure of this object is based on the StimulationData object we
%   wrote for the BCM stimulation system.
%
% AE 2012-08-30

eventTypes = {'userInteraction',  3,  0; ...
          'userInteraction',  3,  1; ...
          'startTrial',      19,  0; ...
          'endTrial',        20,  0; ...
          'endTrial',        20,  1; ...
          'endSession',      20,  2; ...
          'endFixSpot',      25,  0; ...
          'showFixSpot',     25,  1; ...
          'emParams',        26,  0; ...
          'emParams',        26,  1; ...
          'endStimulus',     28,  0; ...
          'showStimulus',    28,  1; ...
          'sound',           35,  0; ...
          'acquireFixation', 36,  1; ...
          'eot',             40,  1; ...
          'eyeAbort',        41,  0; ...
          'reward',          42,  0; ...
          };
stim.eventTypes = unique(eventTypes(:,1));

% load qnx structure
qnx = dg_read(getLocalPath(qnxFile));

% find correct trials
E_REWARD = 42;
nTrials = length(qnx.e_types);
validTrials = repmat(false,1,nTrials);
for i = 1:nTrials
    validTrials(i) = any(qnx.e_types{i} == E_REWARD);
end

% process stimulus parameters
p = [qnx.e_params{validTrials}];
p = [p{6,:}];

switch expType
    case 'mgrad'
        params = {'orientation',   'condition'; ...
                  'contrast',      'condition'; ...
                  'blockNumber',   'trial'; ... 
                  'numSineWaves',  'fixed'; ...
                  'diskSize',      'fixed'; ...
                  'xOffset',       'fixed'; ...
                  'yOffset',       'fixed'; ...
                  'gratingScale'   'fixed'; ...
                  };
        
    case 'movgrad'
        params = {'orientation',   'condition'; ...
                  'contrast',      'condition'; ...
                  'blockNumber',   'trial'; ... 
                  'numSineWaves',  'fixed'; ...
                  'diskSize',      'fixed'; ...
                  'xOffset',       'fixed'; ...
                  'yOffset',       'fixed'; ...
                  'gratingScale'   'fixed'; ...
                  };
end

% fixed parameters
ndx = strmatch('fixed',params(:,2),'exact');
for i = 1:length(ndx)
stim.params.constants.(params{ndx(i),1}) = p(ndx(i),1);
    if length(unique(p(ndx(i),:))) > 1
        error('Parameter %s not fixed for the whole session!',params{ndx(i),1})
    end
end

% get some more fixed parameters from qnx.e_pre
for i = 1:length(qnx.e_pre)
    if strcmp(qnx.e_pre{i}{2}, 'FixHoldTime')
        stim.params.constants.holdFixationTime = str2double(qnx.e_pre{i+1}{2});
    elseif strcmp(qnx.e_pre{i}{2}, 'Stim Time')
        stim.params.constants.stimulusTime = str2double(qnx.e_pre{i+1}{2});
    elseif strcmp(qnx.e_pre{i}{2}, 'Intertrial')
        stim.params.constants.intertrialTime = str2double(qnx.e_pre{i+1}{2});
    end
end

% condition parameters
ndx = strmatch('condition',params(:,2),'exact');
[condVals,foo,condIndices] = unique(p(ndx,:)','rows');
for i = 1:size(condVals,1)
    for j = 1:length(ndx)
        stim.params.conditions(i).(params{ndx(j)}) = condVals(i,j);
    end
end

% per trial parameters
paramNdx = strmatch('trial',params(:,2),'exact');

% extend condition indices to all trials (i.e. put -1 for invalid trials)
condIndicesAll = NaN(1,nTrials);
condIndicesAll(validTrials) = condIndices;

% extend per trial parameters to all trials (i.e. put NaN for invalid trials)
pAll = NaN(size(p,1),nTrials);
pAll(:,validTrials) = p;

% build table to translate qnx types to StimulationData event indices
evtTableSize = [max([eventTypes{:,2}]),max([eventTypes{:,3}]) + 1];
evtTable = zeros(evtTableSize);
for i = 1:size(eventTypes,1)
    ndx = strmatch(eventTypes{i,1},stim.eventTypes(:,1));
    evtTable(eventTypes{i,2},eventTypes{i,3} + 1) = ndx;
end

% read events structure
% It contains absolute times relative to the same clock as the spikes. These are
% used to adjust the qnx times which are relative to the first trial.
events = read_events(fullfile(getLocalPath(cheetahDir),'Events.Nev'));

% determine events corresponding to the trials in the qnx structure
if ischar(chtEvtBeg)
    chtEvtBeg = strmatch(chtEvtBeg,events.es,'exact');
    if numel(chtEvtBeg) ~= 1
        error('No unique ''chtEvtBegin''! %d occurences found.',numel(chtEvtBeg))
    end
end
if ischar(chtEvtEnd)
    chtEvtEnd = strmatch(chtEvtEnd,events.es,'exact');
    if numel(chtEvtEnd) ~= 1
        error('No unique ''chtEvtEnd''! %d occurences found.',numel(chtEvtEnd))
    end
end

% get rid of typed in events
evtNdx = strmatch('RecID: 4098 Port: 0 TTL Value: 0x8000', ...
    events.es(chtEvtBeg:chtEvtEnd),'exact') + chtEvtBeg - 1;
if length(evtNdx) ~= nTrials
    warning('StimulusData:import', ...
        'Number of events in events file and number of trials do not match!')
    if length(evtNdx) < nTrials
        nTrials = length(evtNdx);
    end
end

% process trials
for i = 1:nTrials
    
    % put events
    stim.events(i).types = evtTable( ...
        sub2ind(evtTableSize,qnx.e_types{i},qnx.e_subtypes{i}+1));
    
    % event times translated to absolute times
    stim.events(i).times = events.t(evtNdx(i)) + qnx.e_times{i};
    
    % throw out duplicate events
    rm = [];
    ndx = find(~diff(stim.events(i).times));
    for n = ndx(:)'
        if isequal(stim.events(i).types(n), stim.events(i).types(n + 1))
            rm(end + 1) = n; %#ok
        end
    end
    stim.events(i).types(rm) = [];
    stim.events(i).times(rm) = [];
    stim.events(i).info = cell(size(stim.events(i).types));

    % per trial parameters (these we only have for valid trials)
    stim.params.trials(i).correctResponse = true; % stub since those are fixation experiments
    stim.params.trials(i).validTrial = validTrials(i);
    stim.params.trials(i).condition = condIndicesAll(i);
    for j = 1:length(paramNdx)
        stim.params.trials(i).(params{paramNdx(j),1}) = pAll(paramNdx(j),i);
    end
    
end

% write output
mkdir(fileparts(outFile))
save(outFile, 'stim')
save(strrep(outFile, '.mat', 'Synched.mat'), 'stim')

readmeText = ['These file were generated from MPI data structures by:\n' ...
    'migration/genStimFileMPI.m\n' ...
    'located in github repo: https://github.com/peabody124/sessions.git\n' ...
    'hash: ' gitHash(mfilename)];
fid = fopen(fullfile(fileparts(outFile), 'readme'), 'w');
fprintf(fid, readmeText);
fclose(fid);

    

