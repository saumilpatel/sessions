function restoreSubjectData()

restoreTables('acq');
restoreTables('cont');
restoreTables('detect');
restoreTables('sort');


function restoreTables(schema)

data = load(schema);
tables = fieldnames(data);
for i = 1:numel(tables)
    eval(sprintf('inserti(%s.%s, data.%s);', ...
        schema, tables{i}, tables{i}));
end
save(schema, tables{:})
