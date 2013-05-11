function [electrodes, artifacts] = spikesTetrodesV2(sourceFile, spikesFile)
% Spike detection callback for tetrodes (improved version)
% AE 2012-11-09

% determine which tetrodes were recorded
br = baseReader(sourceFile);
tetrodes = getTetrodes(br);
refs = getRefs(br);
channels = [arrayfun(@(x) sprintf('t%dc*', x), tetrodes, 'uni', false), ...
              arrayfun(@(x) sprintf('ref%d', x), refs, 'uni', false)];
electrodes = [tetrodes, refs + 100];
close(br);

n = numel(electrodes);
artifacts = cell(1, n);
if exist('matlabpool', 'file')
    matlabpool
    parfor i = 1:n
        artifacts{i} = run(spikesFile, sourceFile, electrodes(i), channels{i});
    end
    matlabpool close
else
    for i = 1:n
        artifacts{i} = run(spikesFile, sourceFile, electrodes(i), channels{i});
    end
end


function artifacts = run(spikesFile, sourceFile, electrode, channel)

if electrode < 100
    fprintf('Extracting spikes on tetrode %d\n', electrode);
else
    fprintf('Extracting spikes on reference %d\n', electrode - 100);
end    
br = baseReader(sourceFile, channel);
outFile = sprintf(strrep(spikesFile, '\', '\\'), electrode);
artifacts = detectSpikesTetrodesV2(br, outFile);
