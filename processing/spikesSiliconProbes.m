function [channels, artifacts] = spikesSiliconProbes(sourceFile, spikesFile)
% Spike detection callback for silicon probes.
% AE 2011-10-26

channels = 1 : 64;
matlabpool
parfor i = channels
% for i = channels
    fprintf('Extracting spikes from channel %d\n', i);
    outFile = sprintf(strrep(spikesFile, '\', '\\'), i);
    detectSpikesSP(sourceFile, i, outFile);
end
matlabpool close
artifacts = cell(1, numel(channels));
