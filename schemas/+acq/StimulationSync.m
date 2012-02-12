%{
acq.StimulationSync (computed)   # synchronization

->acq.Stimulation
---
sync_network        : boolean # network synchronization was done
sync_diode          : boolean # synchronized to photodiode
residual_rms = NULL : float   # residual root mean square
diode_offset = NULL : float   # offset between photodiode and labview timer
%}

classdef StimulationSync < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('acq.StimulationSync');
        popRel = (acq.Stimulation - acq.StimulationIgnore) & acq.SessionsCleanup;
    end
    
    methods
        function self = StimulationSync(varargin)
            self.restrict(varargin{:})
        end
        
        
        function makeTuples(self, key)
            tuple = key;
            tuple.sync_network = false;
            stim = getStim(acq.Stimulation(key));

            % check if session was recorded
            ephysKey = fetch(acq.EphysStimulationLink(key));
            tuple.sync_diode = ~isempty(ephysKey);
            
            % catch Blackrock recordings (no network, different method for
            % photodiode sync)
            if tuple.sync_diode && strcmp(fetch1(acq.Sessions(ephysKey), 'recording_software'), 'Blackrock')
                [stim, tuple.residual_rms, tuple.diode_offset] = syncEphysBlackrock(stim, ephysKey); %#ok
            else
            
                % network sync
                [stim, tuple.residual_rms] = syncNetwork(stim, key);
                tuple.sync_network = true;

                % was the session recorded? -> sync to photodiode
                if ~isempty(ephysKey)
                    % catch old sessions where hardware clocks weren't phase locked
                    if fetch1(acq.Ephys(ephysKey), 'ephys_start_time') < dateToLabviewTime('2012-02-08 18:00')
                        [stim, rms, offset] = syncEphysProblems(stim, ephysKey); %#ok
                    else
                        [stim, rms, offset] = syncEphys(stim, ephysKey); %#ok
                    end
                    tuple.residual_rms = rms;
                    tuple.diode_offset = offset;
                    tuple.sync_diode = true;
                end
            end
            
            save(getFileName(acq.Stimulation(key), 'Synched'), 'stim');
            insert(self, tuple);
            if tuple.sync_diode
                insert(acq.StimulationSyncDiode, fetch(acq.EphysStimulationLink(key)));
            end
        end
    end
end
