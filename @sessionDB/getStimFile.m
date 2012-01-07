function [fn stimFiles] = getStimFile(sDb, stim, variant)
% Returns the stimulation file name and file.  Accepts an optional variant
% liked Synced to postpend to name
%
% [fn stimFiles] = getStimFile(sDb, stim, variant)
%
% JC 2011-08

if (nargin < 3)
    variant = '';    
end

for i = 1:length(stim)
    fn{i} = getLocalPath(['/stor01/' stim(i).stim_path '/' stim(i).exp_type variant '.mat']);
    stimFiles(i) = getfield(load(fn{i}),'stim');
end
