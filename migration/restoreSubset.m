function restoreSubset(filename)
% Restore a backup created by backupSubset.
%   restoreSubset(filename) reads the backup file created by backupSubset
%   and restores it to the database.
%
% AE 2012-06-29

backup = load(filename);
for iTable = 1 : numel(backup.tables)
    inserti(eval(backup.tables{iTable}), backup.data{iTable});
end
fprintf('Restored backup successfully.\n')
