function [tetrodes, artifacts] = spikesTetrodesV2(sourceFile, spikesFile)
% Spike detection callback for tetrodes ver. 2
% AE 2013-02-18

% determine which tetrodes were recorded
br = baseReader(sourceFile);
tetrodes = getTetrodes(br);
close(br);

n = numel(tetrodes);
artifacts = cell(1, n);
if exist('matlabpool', 'file')
    matlabpool
    parfor i = 1:n
        artifacts{i} = run(spikesFile, sourceFile, tetrodes(i));
    end
    matlabpool close
else
    for i = 1:n
        artifacts{i} = run(spikesFile, sourceFile, tetrodes(i));
    end
end


function artifacts = run(spikesFile, sourceFile, tetrode)

fprintf('Extracting spikes from tetrode %d\n', tetrode);
outFile = sprintf(strrep(spikesFile, '\', '\\'), tetrode);
artifacts = detectSpikesTetrodesV2(sourceFile, tetrode, outFile);
