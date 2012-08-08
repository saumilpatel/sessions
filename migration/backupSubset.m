function backupSubset(filename, tables, varargin)
% Backup subsets of database tables identified by common restrictions.
%   backup(filename, tables, key) creates a backup file containing all
%   tuples from the given tables matching the specified key. 
%
%   Inputs: 
%       filename    name of the Matlab file containing the backup. The file
%                   contains the variable tables (see below) and a cell
%                   called data which contains the tuples for each of the
%                   specified tables.
%       tables      cell array of strings containing the names of the
%                   tables to be backed up (including the schema, e.g.
%                   {'acq.Subjects', 'acq.Sessions', ...}
%       key         A key (or any other restriction) that is used to
%                   restrict the tuple that are backed up
%
%   Use restoreSubset to restore the file to the database.
%
% AE 2012-06-29

data = cell(size(tables));
for iTable = 1 : numel(tables)
    data{iTable} = fetch(eval(tables{iTable}) & varargin, '*');
end
data
save(filename, 'tables', 'data','-v7.3')
fprintf('Saved backup at %s\n', which(filename))
