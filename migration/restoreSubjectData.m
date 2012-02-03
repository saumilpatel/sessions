function restoreSubjectData()

tables = {'Sessions', 'SessionsIgnore', 'SessionsCleanup', 'Ephys', ...
    'EphysIgnore', 'Stimulation', 'StimulationIgnore', 'EphysTasks', ...
    'EphysStimulationLink', 'StimulationSync', 'BehaviorTraces'};
restoreTables('acq', tables);
   
tables = {'Mua', 'Lfp'};
restoreTables('cont', tables);

tables = {'Params', 'Sets', 'Electrodes'};
restoreTables('detect', tables);

tables = {'Params', 'Sets', 'SetsCompleted', 'Electrodes'};
restoreTables('sort', tables);


function restoreTables(schema, tables)

load(schema);
for i = 1:numel(tables)
    eval(sprintf('insert(%s.%s, %s);', ...
        schema, tables{i}, tables{i}));
end
save(schema, tables{:})
