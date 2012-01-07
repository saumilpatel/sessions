function processUtahSet(sDb, key, varargin)
% processSet(sDb, detectionSet) 
% JC 2011-09-26

% Clustering a Utah array set
% 1. Cache data to local directory
% 2. Extract common reference
% 3. Detect all the spikes for all channels
% 4. Detect LFP for all the channels
% 5. Copy output files to final locationmysql

params.tempDirectory = getfield(struct(sDb),'scratch');
params.destinationDirectory = '/stor01/processed';
params.outfileDirectory = 'c:/processed';
params.electrodes = 1:96;
params = parseVarArgs(params, varargin{:});

assert(count(sessions.Ephys(key)) == 1, 'Only one set should match this key');

ds = fetch(ephys.DetectionSetParam(key,'detection_method="Utah"') ./ ephys.DetectionSet,'*');
assert(length(ds) == 1, 'There should be a detection set here');

% Stage the data
sourceDir = getGlobalPath(fetch1(sessions.Ephys(key), 'ephys_path'));
sourceDir = fileparts(sourceDir);

lfpDir = [strrep(sourceDir, '/raw','/processed') '_lfp'];
tempDir = strrep(sourceDir, '/raw', params.tempDirectory);
outDir = strrep(sourceDir, '/raw', params.outfileDirectory);
sourceDir = fileparts(rawToSource(sessionDB, [sourceDir  '/Electrophysiology%d.h5']));


fileNames = dir(fullfile(sourceDir, 'Electrophysiology*'));

% Copy the files
tic
mkdir(tempDir)
for i = 1:length(fileNames)
    if ~exist(fullfile(tempDir, fileNames(i).name),'file') || fileNames(i).bytes ~= getfield(dir(fullfile(tempDir, fileNames(i).name)), 'bytes')
        disp(['Copying file ' fileNames(i).name ' [' num2str(i) '/' num2str(length(fileNames)) ']']);
        copyfile(fullfile(sourceDir, fileNames(i).name), fullfile(tempDir, fileNames(i).name));
    else
        disp(['Skipped copying ' fileNames(i).name]);
    end
end
copytime = toc;

sourceFile = fullfile(tempDir, 'Electrophysiology%u.h5');

% If we need to process an LFP kick of that job now on a thread
if count(ephys.LfpExtraction(key)) == 0
    % Detect the lfp
    jm = findResource('scheduler', 'configuration', 'local');
    lfpjob = batch(jm,@extract_electrode_lfp, 0, {sourceFile,outDir});
    lfpstart = now;
end

% Extract common reference
tic
extract_common_reference(getGlobalPath(sourceFile));
extractime = toc;

% Open pool of remaining processors
matlabpool

% For each Utah detection set
%TODO: Take into account time frames as that is what would vary
assert(length(ds) == 1, 'Multiple time frames not yet implemented');

% Detect all the spikes
tic
parfor el = params.electrodes
    %         for el = params.electrodes
    disp(['Extracting spikes from channel' num2str(el)]);
    outFile{el} = fullfile(outDir, sprintf('/Sc%03u.Hsp',el));
    detectSpikes(sourceFile,outFile{el},'tetrode',[],'channels',el);
end
detecttime(i) = toc;

ephysSetPath = fetch1(ephys.DetectionSetParam(ds), 'ephys_processed_directory');
assert(~isempty(ephysSetPath), 'Could not get destination path');

outPath = [ephysSetPath '_' ds.detection_method];
mkdir(getDestPath(sDb, outPath));
% If the whole set completed successfully copy data then make appropriate DJ entries
for el = params.electrodes
    copyfile(outFile{el}, getDestPath(sDb, outPath));
    delete(outFile{el});
end

detectionSet = fetch(ephys.DetectionSetParam(ds));
detectionSet.detection_set_directory = outPath;
insert(ephys.DetectionSet, detectionSet);
for el = params.electrodes
    detectionElectrode = fetch(ephys.DetectionSetParam(ds));
    detectionElectrode.electrode_number = el;
    [a fn ext] = fileparts(outFile{el});
    detectionElectrode.detection_electrode_filename = [outPath '/' fn ext];
    insert(ephys.DetectionElectrode, detectionElectrode);
end

matlabpool close

lfptime = [];
if count(ephys.LfpExtraction(key)) == 0
    % Detect the lfp
    disp('Waiting on LFP');
    while ~wait(lfpjob, 'finished',60);
        fprintf('.');
    end
    assert(isempty(lfpjob.Tasks.Error), ['Error extracting the lfp: ' lfpjob.Tasks.Error.message]);
    diary(lfpjob)
    mkdir(getDestPath(sDb, lfpDir))
    copyfile(fullfile(outDir,'lfp*'),getDestPath(sDb, lfpDir));    

    lfp = fetch(pro(sessions.Ephys(key)));
    lfp.lfp_path = lfpDir;
    insert(ephys.LfpExtraction, lfp);
    
    lfptime = (now - lfpstart) * 24 * 60 * 60;
end


% Unstage the data
for i = 1:length(fileNames)
%    leave commented until we confirm this isn't happen on at_scratch directly
%    OR even delete from there automatically
     delete(fullfile(tempDir, fileNames(i).name))
end

delete(tempDir)

disp(['Staging time ' num2str(copytime)]);
disp(['Common reference time ' num2str(extractime)]);
disp(['Detection time ' num2str(detecttime)]);
disp(['LFP time ' num2str(lfptime)]);

