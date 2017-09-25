function [channels, artifacts] = spikesSiliconProbes(sourceFile, spikesFile)
% Spike detection callback for silicon probes.
% AE 2011-10-26

channels = 1 : 32; % GD changed 2015-01-15, as we are using 32 ch probes for now
matlabpool
parfor i = channels
% for i = channels
    fprintf('Extracting spikes from channel %d\n', i);
    outFile = sprintf(strrep(spikesFile, '\', '\\'), i);
    detectSpikesSP(sourceFile, i, outFile);
end
matlabpool close
artifacts = cell(1, numel(channels));
