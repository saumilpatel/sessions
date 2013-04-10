function [tetrodes, artifacts] = spikesTetrodes(sourceFile, spikesFile)
% Spike detection callback for tetrodes
% AE 2011-10-26

% determine which tetrodes were recorded
br = baseReader(sourceFile);
tetrodes = getTetrodes(br);
close(br);

if exist('matlabpool', 'file')
    matlabpool
    parfor i = 1 : numel(tetrodes)
        run(spikesFile, sourceFile, tetrodes(i))
    end
    matlabpool close
else
    for i = 1 : numel(tetrodes)
        run(spikesFile, sourceFile, tetrodes(i))
    end
end

artifacts = cell(1, numel(tetrodes));


function run(spikesFile, sourceFile, tetrode)

fprintf('Extracting spikes from tetrode %d\n', tetrode);
outFile = sprintf(strrep(spikesFile, '\', '\\'), tetrode);
detectSpikesTetrodes(sourceFile, tetrode, outFile);

