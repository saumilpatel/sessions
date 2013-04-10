function backupSubset(folder, tables, varargin)
% Backup subsets of database tables identified by common restrictions.
%   backup(folder, tables, key) creates a backup file containing all
%   tuples from the given tables matching the specified key. 
%
%   Inputs: 
%       folder      name of the folder containing the backup. Each table
%                   is stored in a file contains the variable tuples (the
%                   table content) and table (the table name).
%       tables      cell array of strings containing the names of the
%                   tables to be backed up (including the schema, e.g.
%                   {'acq.Subjects', 'acq.Sessions', ...}
%       key         A key (or any other restriction) that is used to
%                   restrict the tuple that are backed up
%
%   Use restoreSubset to restore the file to the database.
%
% AE 2013-04-10

for iTable = 1 : numel(tables)
    table = tables{iTable};
    fprintf('backing up table %s... ', table)
    tuples = fetch(eval(table) & varargin, '*');
    ndx = find(table == '.', 1);
    subfolder = table(1 : ndx - 1);
    file = table(ndx + 1 : end);
    if ~exist(fullfile(folder, subfolder), 'file')
        mkdir(fullfile(folder, subfolder));
    end
    save(fullfile(folder, subfolder, file), 'table', 'tuples', '-v7.3')
    fprintf('done\n')
end

