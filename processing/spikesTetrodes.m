function tetrodes = spikesTetrodes(sourceFile, spikesFile)
% Spike detection callback for tetrodes
% AE 2011-10-26

% determine which tetrodes were recorded
br = baseReader(sourceFile);
tetrodes = getTetrodes(br);
close(br);

matlabpool

% for i = 1:numel(tetrodes)
parfor i = 1:numel(tetrodes)
    fprintf('Extracting spikes from tetrode %d\n', tetrodes(i));
    outFile = sprintf(strrep(spikesFile, '\', '\\'), tetrodes(i));
    detectSpikesTetrodes(sourceFile, tetrodes(i), outFile);
end

matlabpool close
