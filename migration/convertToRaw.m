function convertToRaw(con)
% Convert absolute paths such as M:\ to /raw
% AE 2011-10-25

update(con, 'sessions', 'session_path')
update(con, 'ephys', 'ephys_path')
update(con, 'behavior_traces', 'beh_path')


function update(con, table, field)

query = ['UPDATE acq.' table ' SET ' field ' = REPLACE(CONCAT("/raw", SUBSTRING(' field ', 3)), "\\", "/") WHERE ' field ' NOT LIKE "/raw%"'];
mym(con, query)
fprintf('Updated %s in table %s\n', field, table)
