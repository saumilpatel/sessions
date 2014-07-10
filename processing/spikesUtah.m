function [electrodes, artifacts] = spikesUtah(sourceFile, spikesFile)
% Spike detection callback for tetrodes
% AE 2011-10-26

% determine which tetrodes were recorded
electrodes = 1:96;

% Extract the common reference
extract_common_reference(sourceFile);

matlabpool

parfor i = 1:numel(electrodes)
    fprintf('Extracting spikes from electrodes %d\n', electrodes(i));
    outFile = sprintf(strrep(spikesFile, '\', '\\'), electrodes(i));
    artifacts{i} = detectSpikesUtah(sourceFile, electrodes(i), outFile);
end

matlabpool close
