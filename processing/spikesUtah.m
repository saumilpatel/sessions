function [electrodes, artifacts] = spikesUtah(sourceFile, spikesFile)
% Spike detection callback for Utah array
% Created by James Cotton on unknown timing
%
% Source file is the raw file specifying pattern e.g.
% 'Electrophysiology%d.h5'
%
% spikesFile - path/naming_pattern designating where detected spikes will
% be saved to

% determine which tetrodes were recorded
electrodes = 1:96;

% Extract the common reference
extract_common_reference(sourceFile, 'channels', electrodes);

matlabpool

parfor i = 1:numel(electrodes)
    fprintf('Extracting spikes from electrodes %d\n', electrodes(i));
    outFile = sprintf(strrep(spikesFile, '\', '\\'), electrodes(i)); % probably only works on Windows
    % call Utah array specific detection routine
    artifacts{i} = detectSpikesUtah(sourceFile, electrodes(i), outFile);
end

matlabpool close
