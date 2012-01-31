function convertBlackrockFileSystemStructure(baseFolder, dataFolders, targetFolder)
% Convert file system structure to Tolias lab conventions
% AE 2012-01-24

fromFormat = 'yyyy-mmm-dd HH-MM-SS';
toFormat = 'yyyy-mm-dd_HH-MM-SS';

for i = 1:numel(dataFolders)
    dayFolder = fullfile(baseFolder, dataFolders{i});
    d = dir(fullfile(dayFolder, '*-*-*'));
    for j = 1:numel(d)
        ephysFolder = datestr(datenum([dataFolders{i} ' ' d(j).name], fromFormat), toFormat);
        toFolder = fullfile(targetFolder, ephysFolder, filesep);
        sourceFiles = fullfile(dayFolder, d(j).name, '*');
        if (numel(dir(sourceFiles)) <= 2)
            continue
        end
        mkdir(toFolder)
        cmd = sprintf('mv %s %s', sourceFiles, toFolder);
        fprintf([cmd '\n'])
        assert(system(cmd) == 0, 'Error while moving files!')
    end
end
