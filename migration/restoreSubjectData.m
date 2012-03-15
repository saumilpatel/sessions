function restoreSubjectData()

tables = {'Subjects', 'Sessions', 'SessionsIgnore', 'SessionsCleanup', 'EphysTypes', ...
    'Ephys', 'EphysIgnore', 'Stimulation', 'StimulationIgnore', ...
    'EphysStimulationLink', 'StimulationSync', 'BehaviorTraces'};
restoreTables('acq', tables);
   
tables = {'Mua', 'Lfp'};
restoreTables('cont', tables);

tables = {'Methods', 'Params', 'Sets', 'Electrodes'};
restoreTables('detect', tables);

tables = {'Methods', 'Params', 'Sets', 'SetsCompleted', 'Electrodes', ...
    'TetrodesMoGAutomatic', 'TetrodesMoGManual', 'TetrodesMoGFinalize', ...
    'TetrodesMoGUnits', 'TetrodesMoGLink', 'MultiUnit'};
restoreTables('sort', tables);


function restoreTables(schema, tables)

load(schema);
for i = 1:numel(tables)
    eval(sprintf('inserti(%s.%s, %s);', ...
        schema, tables{i}, tables{i}));
end
save(schema, tables{:})
