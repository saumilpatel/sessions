function [channels, artifacts] = spikesSiliconProbesV2(sourceFile, spikesFile)
% Spike detection callback for silicon probes.
% AE 2011-10-26


channels = 1 : 32;

% Extract the common reference - mean across channels at each timepoint
extract_common_reference(sourceFile, 'channels', channels);

matlabpool

parfor i = channels
    fprintf('Extracting spikes from channel %d\n', i);
    outFile = sprintf(strrep(spikesFile, '\', '\\'), i);
    detectSpikesSPV2(sourceFile, i, outFile);
end

matlabpool close
artifacts = cell(1, numel(channels));
