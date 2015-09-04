function [electrodes, artifacts] = spikesMultiChannelProbes(sourceFile, spikesFile, channels)
% Spike detection callback for multi-channel probes
% AE 2015-07-01

n = size(channels, 1);
artifacts = cell(1, n);
if exist('parpool', 'file')
   parpool
   parfor i = 1 : n
       artifacts{i} = run(spikesFile, sourceFile, i, channels(i, :));
   end
else
    for i = 1 : n
        artifacts{i} = run(spikesFile, sourceFile, i, channels(i, :));
    end
end
electrodes = 1 : n;


function artifacts = run(spikesFile, sourceFile, electrode, channels)

fprintf('Extracting spikes on channel group %d\n', electrode);
channels = arrayfun(@(c) sprintf('s1c%d', c), channels, 'uni', false);
br = baseReader(sourceFile, channels);
outFile = sprintf(strrep(spikesFile, '\', '\\'), electrode);
artifacts = detectSpikesTetrodesV2(br, outFile);
