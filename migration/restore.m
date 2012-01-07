function restore(folder)

ins(folder, 'Subjects')
ins(folder, 'TimestampSources')
ins(folder, 'Sessions')
ins(folder, 'SessionsIgnore')
ins(folder, 'Ephys')
ins(folder, 'EphysIgnore')
ins(folder, 'Stimulation')
ins(folder, 'StimulationIgnore')
ins(folder, 'StimulationSync')
ins(folder, 'BehaviorTraces')
ins(folder, 'BehaviorTracesIgnore')
ins(folder, 'SessionTimestamps')
ins(folder, 'EphysStimulationLink')
ins(folder, 'TberPulses')


function ins(folder, table)

fprintf('Restoring table %s...', table)
load(fullfile(folder, table))
insert(eval(['acq.' table]), contents, 'INSERT IGNORE')
fprintf(' done\n')
