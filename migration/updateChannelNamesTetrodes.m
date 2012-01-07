function updateChannelNamesTetrodes(subjectFolder)
% Update channel names in some early files
%   updateChannelNamesTetrodes('M:\Charles')
%
%   * Renames reference channels from t26c* to ref*
%   * Renames photodiode channel from t27c3_photodiode and the like to
%     Photodiode
%   * Renames Voltage_* to t*c* in case the wrong task (All4498s) was used
%
% AE 2011-10-16

firstCh = [7 15 22 30 38 47 31 39 46 6 14 23 55 63 70 78 86 95 79 87 94 54 62 71]';
n = 96;
tetCh = bsxfun(@minus, firstCh, 0:2:6);
assert(isequal(unique(tetCh(:))', 0:n-1))
subs = cell(24, 2);
for i = 1:n
    [tet, ch] = find(tetCh == i-1);
    subs(i,:) = {sprintf('Voltage_%d,', i-1), sprintf('t%dc%d,', tet, ch)};
end
for i = 1:4
    subs(n+i,:) = {sprintf('Voltage_%d,', 104-i), sprintf('t26c%d,', i)};
end

subs = [subs; { ...
    't26c', 'ref'; ...                      t26c1 is ref1 and so on
    'Ref', 'ref'; ...
    't27c3_photodiode', 'Photodiode'; ...   setup 1
    't28c4_photodiode', 'Photodiode'; ...   setup 3
    't28c4', 'Photodiode'; ...              setup 3
}];

pattern = '*-*-*_*-*-*';
sessionFolders = dir(fullfile(subjectFolder, pattern));
for sessionFolder = sessionFolders'
    subFolders = dir(fullfile(subjectFolder, sessionFolder.name, pattern));
    for subFolder = subFolders'
        ephysFile = fullfile(subjectFolder, sessionFolder.name, subFolder.name, 'Electrophysiology%d.h5');
        if exist(sprintf(strrep(ephysFile, '\', '/'), 0), 'file') % contains ephys recording
            try
                fp = H5Tools.openFamily(ephysFile, 'H5F_ACC_RDWR');
            catch err
                warning(err.message)
                continue
            end
            c = H5Tools.readAttribute(fp, 'channelNames')';
            c2 = c;
            % do substitutions
            for i = 1:size(subs, 1)
                c = strrep(c, subs{i,:});
            end
            if isequal(c, c2)
                fprintf('Everything alright with file %s\n', ephysFile)
            else
                if isempty(strfind(c, 'Photodiode'))
                    warning('No photodiode channel found in file %s.\n  Updated channel names are\n%s\n', ephysFile, c) %#ok
                end
                % make backup
                H5Tools.writeAttribute(fp, 'channelNamesOriginal', c2');
                % do update by delete and re-create
                H5A.delete(fp, 'channelNames');
                H5Tools.writeAttribute(fp, 'channelNames', c');
                fprintf('Updated channel names in file %s\n', ephysFile)
            end
            H5F.close(fp);
        end
    end
end
