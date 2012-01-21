function processSet(key, spikesCb, spikesFile, lfpCb, muaCb, pathCb, useTempDir)
% TODO: write documentation

if nargin < 8
    useTempDir = true;
end

maxFiles = 200; % maximum number of files that fit on temp storage right now

assert(isfield(key, 'setup') && isfield(key, 'session_start_time') && isfield(key, 'ephys_start_time'), isfield(key, 'detect_method_num'), 'Incomplete primary key!')
assert(count(detect.Params(key)) == 1, 'Did not find a detection that matches this key!')
assert(~count(detect.Sets(key)), 'This set is already processsed. Delete it first if you want to reprocess.')

% determine folder and file names
sourceFile = fetch1(acq.Ephys(key), 'ephys_path');
[recDir, dataFile, ext] = fileparts(sourceFile);
dataFile = [dataFile ext];
dataFilePattern = strrep(strrep(dataFile, '%d', '*'), '%u', '*');
processedDir = fetch1(detect.Params(key), 'ephys_processed_path');
localProcessedDir = getLocalPath(processedDir);
detectMethod = fetch1(detect.Methods & detect.Params(key), 'detect_method_name');
spikesDir = fullfilefs('spikes', detectMethod);
lfpDir = 'lfp';
lfpFile = 'lfp%d';
muaFile = 'amua%d';

% make sure files fit on temp drive
map = RawPathMap;
if useTempDir
    fromDir = findFile(map, recDir);
    files = dir(fullfilefs(fromDir, dataFilePattern));
    if numel(files) > maxFiles
        useTempDir = false;
    end
end

% stage the files
if useTempDir
    tempDir = toTemp(map, recDir);
    mkdir(tempDir);
    fprintf('Copying %d files from %s\n                   to %s\n', numel(files), fromDir, tempDir)
    for file = files'
        toFile = fullfilefs(tempDir, file.name);
        toFileInfo = dir(toFile);
        if exist(toFile, 'file') && toFileInfo.bytes == file.bytes
            fprintf('  Skipping file %s\n', file.name)
        else
            fprintf('  Copying file %s\n', file.name)
            fromFile = fullfilefs(fromDir, file.name);
            copyfile(fromFile, toFile);
        end
    end
    sourceFile = toTemp(map, sourceFile);
    destDir = tempDir;
else
    sourceFile = findFile(map, sourceFile);
    destDir = localProcessedDir;
end

matlabpool close force local

% If we need to process an LFP kick of these jobs now on a thread
if ~count(cont.Lfp(key)) && ~isempty(lfpCb)
    outDir = fullfilefs(destDir, lfpDir);
    createOrEmpty(outDir)
    scheduler = findResource('scheduler', 'configuration', 'local');
    if ~isempty(scheduler.Jobs) % cancel jobs that are still running from a crash
        scheduler.Jobs.destroy();
    end
    p = pathCb();
    lfpJob = batch(scheduler, lfpCb, 0, {sourceFile, fullfilefs(outDir, lfpFile)}, 'PathDependencies', p);
    muaJob = batch(scheduler, muaCb, 0, {sourceFile, fullfilefs(outDir, muaFile)}, 'PathDependencies', p);
end

% create or clear output directory for spikes
outDir = fullfilefs(destDir, spikesDir);
createOrEmpty(outDir)

% run callback for spike detection
outFile = fullfilefs(outDir, spikesFile);
electrodes = spikesCb(sourceFile, outFile);

% wait for LFP & MUA jobs to finish
if ~count(cont.Lfp(key)) && ~isempty(lfpCb)
    disp('Waiting on LFP');
    while ~wait(lfpJob, 'finished', 60);
        fprintf('.');
    end
    diary(lfpJob)
    assert(isempty(lfpJob.Tasks.Error), 'Error extracting LFP: %s', lfpJob.Tasks.Error.message);
    
    disp('Waiting on MUA');
    while ~wait(muaJob, 'finished', 60);
        fprintf('.');
    end
    diary(muaJob)
    assert(isempty(muaJob.Tasks.Error), 'Error extracting MUA: %s', muaJob.Tasks.Error.message);
    
    lfpCb = rmfield(key, 'detect_method_num');
    lfpCb.lfp_file = fullfilefs(processedDir, lfpDir, lfpFile);
    insert(cont.Lfp, lfpCb);
    
    muaCb = rmfield(key, 'detect_method_num');
    muaCb.mua_file = fullfilefs(processedDir, lfpDir, muaFile);
    insert(cont.Mua, muaCb);
end

% populate database tables
tuple = key;
tuple.detect_set_path = fullfilefs(processedDir, spikesDir);
insert(detect.Sets, tuple);
for e = electrodes
    tuple = key;
    tuple.electrode_num = e;
    tuple.detect_electrode_file = fullfilefs(processedDir, spikesDir, sprintf(spikesFile, e));
    insert(detect.Electrodes, tuple);
end

if useTempDir
    % remove raw data files
    delete(fullfilefs(tempDir, dataFilePattern));
    
    % copy output files to processed folder
    if exist(localProcessedDir, 'file')
        rmdir(localProcessedDir, 's');
    end
    mkdir(localProcessedDir);
    copyfile(destDir, localProcessedDir);
    
    % delete temp data
    rmdir(tempDir, 's');
end




function createOrEmpty(outDir)
% Creates a directory. If it already exists, files in it are deleted.

if exist(outDir, 'file')
    rmdir(outDir, 's');
end
mkdir(outDir);


function f = fullfilefs(varargin)
% fullfile with forward slashes instead of os-specific slashes

f = strrep(fullfile(varargin{:}), '\', '/');
