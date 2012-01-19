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
        popRel = acq.Stimulation('stim_stop_time IS NOT NULL');
    end
    
    methods
        function self = StimulationSync(varargin)
            self.restrict(varargin{:})
        end
        
        
        function makeTuples(self, key)
            tuple = key;
            tuple.sync_diode = false;
            stim = getStim(acq.Stimulation(key));
            
            % network sync
            [stim, tuple.residual_rms] = syncNetwork(stim, key);
            tuple.sync_network = true;
            
            % was the session recorded? -> sync to photodiode
            ephysKey = fetch(acq.EphysStimulationLink(key));
            if ~isempty(ephysKey)
                [stim, tuple.residual_rms, tuple.diode_offset] = syncEphys(stim, ephysKey); %#ok
                tuple.sync_diode = true;
            end
            
            save(getFileName(acq.Stimulation(key), 'Synched'), 'stim');
            insert(self, tuple);
        end
    end
end
