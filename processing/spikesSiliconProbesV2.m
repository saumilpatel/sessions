function [channels, artifacts] = spikesSiliconProbesV2(sourceFile, spikesFile)
% Spike detection callback for silicon probes.
% AE 2011-10-26
% GD 2015-01-13 added line to extract common reference

channels = 1 : 32; % GD changed on 2014-11-03

% Extract the common reference - mean across channels at each timepoint
extract_common_reference(sourceFile);

matlabpool

parfor i = channels
    fprintf('Extracting spikes from channel %d\n', i);
    outFile = sprintf(strrep(spikesFile, '\', '\\'), i);
    detectSpikesSP(sourceFile, i, outFile);
end

matlabpool close
artifacts = cell(1, numel(channels));
