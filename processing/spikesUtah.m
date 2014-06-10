function [electrodes, artifacts] = spikesUtah(sourceFile, spikesFile)
% Spike detection callback for tetrodes
% AE 2011-10-26
% 
% Updated to reflect Utah array specific detect method invocation used on 
% at-detect
% EW 2014-06-02

% determine which tetrodes were recorded
electrodes = 1:96;

% Extract the common reference
extract_common_reference(sourceFile);

matlabpool

parfor i = 1:numel(electrodes)
    fprintf('Extracting spikes from electrodes %d\n', electrodes(i));
    outFile = sprintf(strrep(spikesFile, '\', '\\'), electrodes(i));
    % call Utah array specific detection routine
    artifacts{i} = detectSpikesUtah(sourceFile, electrodes(i), outFile);
end

matlabpool close
