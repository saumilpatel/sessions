function channels = spikesSiliconProbes(sourceFile, spikesFile)
% Spike detection callback for silicon probes.
% AE 2011-10-26

% determine which tetrodes were recorded
br = baseReader(sourceFile, 's1c*');
channels = getNbChannels(br);
close(br);

matlabpool

% for i = 1:numel(tetrodes)
parfor i = 1:channels
    fprintf('Extracting spikes from channel %d\n', i);
    outFile = sprintf(strrep(spikesFile, '\', '\\'), i);
    detectSpikesSP(sourceFile, i, outFile);
end

matlabpool close

channels = 1:channels;
