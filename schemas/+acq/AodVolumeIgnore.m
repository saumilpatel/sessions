%{
acq.AodVolumeIgnore (manual) # my newest table
-> acq.AodVolume

-----

%}

classdef AodVolumeIgnore < dj.Relvar

	properties(Constant)
		table = dj.Table('acq.AodVolumeIgnore')
	end

	methods
		function self = AodVolumeIgnore(varargin)
			self.restrict(varargin)
		end
    end
    
    methods (Static)
        function findShortVolumes
            volumes = fetch(acq.AodVolume - acq.AodVolumeIgnore);
            for i = 1:length(volumes)
                try
                vol = getFile(acq.AodVolume & volumes(i));
                if vol.sz(1) / (length(vol.x) * length(vol.y) * length(vol.z)) < 1
                    disp('Found short scan')
                    insert(acq.AodVolumeIgnore, fetch(acq.AodVolume & volumes(i)));
                end
                catch
                end
            end
        end
    end
end
