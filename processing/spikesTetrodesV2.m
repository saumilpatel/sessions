function [tetrodes, artifacts] = spikesTetrodesV2(sourceFile, spikesFile)
% Spike detection callback for tetrodes (improved version)
% AE 2012-11-09

% determine which tetrodes were recorded
br = baseReader(sourceFile);
tetrodes = getTetrodes(br);
close(br);

matlabpool

artifacts = cell(1, numel(tetrodes));
parfor i = 1:numel(tetrodes)
    fprintf('Extracting spikes from tetrode %d\n', tetrodes(i));
    outFile = sprintf(strrep(spikesFile, '\', '\\'), tetrodes(i));
    artifacts{i} = detectSpikesTetrodesV2(sourceFile, tetrodes(i), outFile);
end

matlabpool close
