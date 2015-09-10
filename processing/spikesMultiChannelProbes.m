function [electrodes, artifacts] = spikesMultiChannelProbes(sourceFile, spikesFile, channels)
% Spike detection callback for multi-channel probes
% AE 2015-07-01

% Extract common reference first
extract_common_reference(sourceFile, 'channels', unique(channels));

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

% Get raw channel and reference data
channels = arrayfun(@(c) sprintf('s1c%d', c), channels, 'uni', false);
raw = baseReader(sourceFile, channels);
refFile = fullfile(fileparts(sourceFile),'ref%d.h5');
ref = baseReader(refFile);

% create referenced reader and call detection method
br = baseReaderReferenced(raw, ref);
outFile = sprintf(strrep(spikesFile, '\', '\\'), electrode);
artifacts = detectSpikesMultiChannelProbes(br, outFile);
