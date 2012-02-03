function backupSubjectData(subjectId)

tables = {'Sessions', 'SessionsIgnore', 'SessionsCleanup', 'EphysTypes', ...
    'Ephys', 'EphysIgnore', 'Stimulation', 'StimulationIgnore', ...
    'EphysStimulationLink', 'StimulationSync', 'BehaviorTraces'};
backupTables('acq', tables, subjectId);
   
tables = {'Mua', 'Lfp'};
backupTables('cont', tables, subjectId);

tables = {'Params', 'Sets', 'Electrodes'};
backupTables('detect', tables, subjectId);

tables = {'Params', 'Sets', 'SetsCompleted', 'Electrodes'};
backupTables('sort', tables, subjectId);


function backupTables(schema, tables, subjectId)

for i = 1:numel(tables)
    eval(sprintf('%s = fetch(%s.%s(''subject_id = %d''), ''*'');', ...
        tables{i}, schema, tables{i}, subjectId));
end
save(schema, tables{:})
