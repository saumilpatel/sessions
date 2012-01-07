function processByFolder(folder)
% runs processTetSession for all subfolders in a given folder
% AE 2011-10-22

for file = dir(fullfile(folder, '*-*-*_*-*-*'))'
    sessKey = fetch(acq.Sessions(sprintf('session_path LIKE "%%%s"', file.name)));
    if ~count(acq.StimulationSync(sessKey))
        processTetSession(sessKey);
    end
end
