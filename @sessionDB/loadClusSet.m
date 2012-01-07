function loadClusSet(sDb, clus_sets_stim, varargin)
% Copies the elements from the preprocessing tool chain to a DJ 
% database for analysis
%
% loadClusSet(sDb, dj, clus_sets_stim)
%
% JC 2011-08-15
%
% E.g. to import all sessions from a given animal
%
% Make sure you connect to DJ first and your DJ user has access
% to sessions tables
%
% session = getSession(sDb, 'Woody');
% clus_sets_stim = getMatches(sDb, 'clus_sets_stim', session)
% loadClusSet(sDb, clus_sets_stim)

params.electrodes = 1:96;
params.clusSetType = {'MultiUnit'};
params = parseVarArgs(params,varargin{:});

if(length(clus_sets_stim) > 1)
    for i = 1:length(clus_sets_stim)
        loadClusSet(sDb, clus_sets_stim(i));
    end
    return
end

%% Get data to insert
subject = mym(sDb.conHandle, ...
    sprintf(['SELECT subject_name,subject_id FROM `sessions`.`subjects` NATURAL JOIN ' ... 
    '`sessions`.`sessions` NATURAL JOIN `sessions`.`clus_sets_stim` WHERE ' ...
    'setup=%16.16g AND stim_start_time=%16.16g'], ...
    clus_sets_stim.setup, clus_sets_stim.stim_start_time));
session = getEntries(sDb, clus_sets_stim, 'sessions');
stim = getEntries(sDb, clus_sets_stim, 'stimulation');
beh = getBehaviorByStimulation(sDb, stim);
ephys = getEntries(sDb, clus_sets_stim, 'ephys');
clus_sets = getEntries(sDb, clus_sets_stim, 'clus_sets');

%% Insert data to ephys database
inserti(Subjects,struct('subject_name',subject.subject_name{1}, ...
    'subject_id',subject.subject_id));
inserti(Sessions,rmfield(session,'table'));
inserti(Stimulation,rmfield(stim,'table'));
inserti(BehaviorTraces,rmfield(beh','table'));
inserti(Ephys,rmfield(ephys,'table'));
inserti(ClusSets,rmfield(clus_sets,'table'));
inserti(ClusSetsStim,rmfield(clus_sets_stim,'table'));
inserti(SpikeSetType,setfield(rmfield(clus_sets_stim,'table'),'spike_set_type','MultiUnit'));

% inserti(SpikeSet,setfield(fetch(rmfield(clus_sets_stim,'table'),'spike_set_type','MultiUnit')))
