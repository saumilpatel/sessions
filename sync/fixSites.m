function eventSites = fixSites(eventTypes)

labView = {'startTrial','showFixSpot','showStimulus','prematureAbort', ...
    'saccade','endStimulus','pause','startTrialSound','eyeAbortSound', ...
    'noResponseSound','leverAbortSound','rewardSound','prematureAbortSound', ...
    'correctResponseSound','incorrectResponseSound','clearScreen'};
pc = {'acquireFixation','response','reward','fixationTimeoutAbort', ...
    'eyeAbort','noResponse','leverAbort'};

eventSitesMac = cellfun(@(x) any(strmatch(x, pc, 'exact')), eventTypes);
eventSitesLabview = cellfun(@(x) any(strmatch(x, labView, 'exact')), eventTypes);

assert(all(eventSitesMac | eventSitesLabview), 'Unrecognized event types');

eventSites = eventSitesMac';