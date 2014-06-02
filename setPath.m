function setPath
    base = fileparts(mfilename('fullpath'));
    addpath(base);
    addpath(fullfile(base, 'processing'));
    addpath(fullfile(base, 'processing/sync'));
    addpath(fullfile(base, 'processing/utils'));
    addpath(fullfile(base, 'recovery'));
    addpath(fullfile(base, 'schemas'));
    addpath(fullfile(base, 'migration'));
    addpath(fullfile(base, 'sortgui'));
    addpath(fullfile(base, 'sortgui/lib'));
    % addpath(fullfile(base, 'sessions/aodgui'))
    % addpath(fullfile(base, 'sessions/lib/two_photon'))
end
