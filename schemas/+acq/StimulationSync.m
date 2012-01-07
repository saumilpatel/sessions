%{
acq.StimulationSync (computed)   # synchronization

->acq.Stimulation
---
sync_network        : boolean  # network synchronization was done
sync_diode          : boolean  # synchronized to photodiode
residual_rms = NULL : float    # residual root mean square
%}

classdef StimulationSync < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('acq.StimulationSync');
        popRel = acq.Stimulation('stim_stop_time IS NOT NULL');
    end
    
    methods
        function self = StimulationSync(varargin)
            self.restrict(varargin{:})
        end
        
        
        function makeTuples(self, key)
            tuple = key;
            tuple.sync_network = false;
            tuple.sync_diode = false;
            
            % load up the sync times
            stim = getStim(acq.Stimulation(key));
            
            % network sync
            try
                [stim, tuple.residual_rms] = syncNetwork(stim, key);
                tuple.sync_network = true;
            catch err
                msg = 'Network synchronization failed (stim_start_time = %ld)\n\nError message:\n%s';
                warning('StimulationSync:syncNetworkFailure', msg, key.stim_start_time, err.message)
            end

            % was the session recorded? -> sync to photodiode
            ephysKey = fetch(acq.EphysStimulationLink(key));
            if ~isempty(ephysKey)
                try
                    [stim, tuple.residual_rms] = syncEphys(stim, ephysKey); %#ok
                    tuple.sync_diode = true;
                catch err
                    msg = 'Synchronization to photodiode failed (stim_start_time = %ld)\n\nError message:\n%s';
                    warning('StimulationSync:syncDiodeFailure', msg, key.stim_start_time, err.message)
                end
            end
            
            % save synchronized file
            if tuple.sync_network || tuple.sync_diode
                save(getFileName(acq.Stimulation(key), 'Synched'), 'stim');
            end
            
            % put stats into db
            insert(self, tuple);
        end
    end
end
