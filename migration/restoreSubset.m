function restoreSubset(folder, tables)
% Restore a backup created by backupSubset.
%   restoreSubset(filename, tables) reads the backup file created by
%   backupSubset and restores it to the database.
%
% AE 2013-04-10

for iTable = 1 : numel(tables)
    table = tables{iTable};
    fprintf('Restoring table %s... ', table)
    ndx = find(table == '.', 1);
    subfolder = table(1 : ndx - 1);
    file = table(ndx + 1 : end);
    backup = load(fullfile(folder, subfolder, file), 'tuples', 'table');
    inserti(eval(backup.table), backup.tuples);
    fprintf('done\n')
end
fprintf('Restored backup successfully.\n\n')
